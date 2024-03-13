# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.

# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).

# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.

# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

# Used to validate oauth signatures
require 'oauth/request_proxy/action_controller_request'

class RegistrationController < ApplicationController
  include RailsLti2Provider::ControllerHelpers
  include ExceptionHandler
  include OpenIdAuthenticator
  include AppsValidator
  include LtiHelper
  include PlatformValidator
  include DynamicRegistrationService

  before_action :print_parameters if Rails.configuration.developer_mode_enabled
  # skip rail default verify auth token - we use our own strategies
  skip_before_action :verify_authenticity_token
  # validates message corresponds to a LTI request
  before_action :process_registration_initiation_request, only: %i[dynamic]

  def dynamic
    # 3.7 Step 4: Registration Completed and Activation
    #   Once the registration is completed, successfully or not, the tool should notify the platform by sending an HTML5 Web Message
    #   [webmessaging] indicating the window may be closed. Depending on whether the platform opened the registration in an IFrame or
    #   a new tab, either window.parent or window.opener should be called.
  end

  def token
    params[:app] ||= params[:custom_broker_app] || Rails.configuration.default_tool
    return if params[:app] == 'default' || params[:custom_broker_app] == 'default'

    # Setting temp keys
    private_key = OpenSSL::PKey::RSA.generate(4096)
    public_key = private_key.public_key

    # keep temp files in scope so they are not deleted
    storage = TemporaryStorage.new
    public_key_file = storage.store('bbb-lti-rsa-pub-', public_key.to_s)
    private_key_file = storage.store('bbb-lti-rsa-pri-', private_key.to_s)

    temp_key_token = SecureRandom.hex

    ActiveRecord::Base.connection.cache do
      Rails.cache.write(temp_key_token, public_key_path: public_key_file.path, private_key_path: private_key_file.path, timestamp: Time.now.to_i)
    end

    redirect_to(json_config_url(app: params[:app], temp_key_token: temp_key_token))
  end

  def pubkeyset
    # The param :key_token is required. It should fail if not included. IT should also fail if not found.
    tool_public_key = Rails.root.join(".ssh/#{params[:key_token]}/pub_key")
    pub = File.read(tool_public_key)
    pub_key = OpenSSL::PKey::RSA.new(pub)

    jwk = pub_key.to_jwk
    jwk['alg'] = 'RS256' unless jwk.key?('alg')
    jwk['use'] = 'sig' unless jwk.key?('use')

    json_pubkeyset = {}
    json_pubkeyset['keys'] = [
      jwk,
    ]

    render(json: JSON.pretty_generate(json_pubkeyset))
  end

  private

  # verify lti 1.3 dynamic registration request
  def process_registration_initiation_request
    logger.debug('>>>>>>>>>> process_registration_initiation_request')
    # Step 1: Step 1: Registration Initiation Request
    begin
      jwt = verify_registration_initiation_request
    rescue StandardError => e
      logger.error("Error in registrtion initiation request verification: #{e}")
      raise e
    end

    @jwt_header = jwt[:header]
    @jwt_body = jwt[:body]

    # 3.4 Step 2: Discovery and openid Configuration
    openid_configuration = discover_openid_configuration(params['openid_configuration'])
    logger.debug(">>>>>>>>>> openid_configuration: \n#{openid_configuration.to_yaml}")

    tenant = RailsLti2Provider::Tenant.first
    logger.debug("Error: Issuer or Platform ID has already been registered for tenant '#{tenant.uid}'.")
    return if RailsLti2Provider::Tool.exists?(uuid: openid_configuration['issuer'], tenant: tenant)

    # 3.5 Step 3: Client Registration
    uri = URI(openid_configuration['registration_endpoint'])
    # 3.5.1 Issuer and OpenID Configuration URL Match
    # validate_issuer(jwt_body)

    # 3.5.2 Client Registration Request
    logger.debug('>>>>>>>>>> 3.5.2 Client Registration Request')
    key_token = new_rsa_keypair
    header = client_registration_request_header(params[:registration_token])
    body = client_registration_request_body(key_token)
    logger.debug(body)
    body = body.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    request = Net::HTTP::Post.new(uri, header)
    request.body = body

    response = http.request(request)
    response = JSON.parse(response.body)
    logger.debug(response)

    # 3.6 Client Registration Response
    logger.debug(">>>>>>>>>> 3.6 Client Registration Response:\n#{response.to_yaml}")
    reg = {
      issuer: openid_configuration['issuer'],
      client_id: response['client_id'],
      key_set_url: openid_configuration['jwks_uri'],
      auth_token_url: openid_configuration['token_endpoint'],
      auth_login_url: openid_configuration['authorization_endpoint'],
      tool_private_key: Rails.root.join(".ssh/#{key_token}/priv_key"),
    }

    tool = RailsLti2Provider::Tool.create(
      uuid: openid_configuration['issuer'],
      shared_secret: response['client_id'],
      tool_settings: reg.to_json,
      lti_version: '1.3.0',
      tenant: tenant,
      status: 'enabled'
    )

    # 3.6.2 Client Registration Error Response
    # IT should return with an error

    # 3.6.1 Successful Registration
    logger.debug(">>>>>>>>>> 3.6.1 Successful Registration:\n#{tool.to_json}")
  end

  def discover_openid_configuration(url)
    JSON.parse(URI.parse(url).read)
  end
end
