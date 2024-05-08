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

  @error_message = ''
  @error_suggestion = ''

  rescue_from ExceptionHandler::CustomError do |ex|
    @error = case ex.error
             when :tenant_not_found, :tool_duplicated
               { code: '406',
                 key: t('error.http._406.code'),
                 message: @error_message,
                 suggestion: @error_suggestion || '',
                 status: '406', }
             else
               { code: '520',
                 key: t('error.http._520.code'),
                 message: t('error.http._520.message'),
                 suggestion: t('error.http._520.suggestion'),
                 status: '520', }
             end
    logger.error("Registration error:\n#{@error.to_yaml}")
    render 'errors/index'
  end

  def dynamic
    # 3.7 Step 4: Registration Completed and Activation
    #   Once the registration is completed, successfully or not, the tool should notify the platform by sending an HTML5 Web Message
    #   [webmessaging] indicating the window may be closed. Depending on whether the platform opened the registration in an IFrame or
    #   a new tab, either window.parent or window.opener should be called.
  end

  def pub_keyset
    # The param :key_token is required. It should fail if not included. It should also fail if not found.
    rsa_key_pair = RsaKeyPair.find_by(token: params[:key_token])
    if rsa_key_pair.nil?
      logger.debug('Error pub_keyset')
      render(json: JSON.pretty_generate({ error: { code: 404, message: 'not found' } }), status: :not_found) && return
    end
    public_key = OpenSSL::PKey::RSA.new(rsa_key_pair.public_key)

    # lookup for the kid
    tool = RailsLti2Provider::Tool.where('tool_settings LIKE ?', "%\"rsa_key_pair_id\":#{rsa_key_pair.id}%").first
    logger.debug("#{rsa_key_pair.id}\n#{tool.to_json}\n")
    if tool.nil?
      logger.debug("Error pub_keyset\n Tool with rsa_key_pair_id=#{rsa_key_pair.id} was not found")
      render(json: JSON.pretty_generate({ error: { code: 404, message: 'not found' } }), status: :not_found) && return
    end
    tool_settings = JSON.parse(tool.tool_settings)
    registration_token = tool_settings['registration_token']
    if registration_token.nil?
      logger.debug("Error pub_keyset\n The 'registration_token' was not found. This tool was registered manually.")
      render(json: JSON.pretty_generate({ error: { code: 404, message: 'not found' } }), status: :not_found) && return
    end

    jwt_parts = registration_token.split('.')
    jwt_header = JSON.parse(Base64.urlsafe_decode64(jwt_parts[0]))

    # prepare the pub_keyset
    json_pub_keyset = {}
    json_pub_keyset['keys'] = [
      {
        kty: 'RSA',
        e: Base64.urlsafe_encode64(public_key.e.to_s(2)).delete('='), # Exponent
        n: Base64.urlsafe_encode64(public_key.n.to_s(2)).delete('='), # Modulus
        kid: jwt_header['kid'],
        alg: 'RS256',
        use: 'sig',
      },
    ]

    render(json: JSON.pretty_generate(json_pub_keyset))
  end

  def link
    @tenant = RailsLti2Provider::Tenant.find_by('metadata ->> :key = :value', key: 'activation_code', value: params[:activation_code])
    logger.debug(@tenant.to_json)
    # Trigger invalid_activation_code error as it was not found
    if @tenant.nil?
      @error_code = 'activation_code_not_found'
      logger.debug(@error_code)
      render(:dynamic) && return
    end
    # Trigger invalid_activation_code error as it is expired
    if @tenant.metadata['activation_code_expire'].nil? || @tenant.metadata['activation_code_expire'] <= Time.current
      @error_code = 'activation_code_expired'
      logger.debug(@error_code)
      render(:dynamic) && return
    end

    @tool = RailsLti2Provider::Tool.find(params[:tool_id])

    unless @tenant.nil? || @tool.nil?
      @tool.tenant = @tenant
      @tool.save
      @tenant.metadata['activation_code_expire'] = Time.current
      @tenant.save
    end
    render(:dynamic)
  end

  private

  # verify lti 1.3 dynamic registration request
  def process_registration_initiation_request
    # 3.3 Step 1: Registration Initiation Request
    begin
      jwt = validate_registration_initiation_request
      @jwt_header = jwt[:header]
      @jwt_body = jwt[:body]
    rescue StandardError => e
      @error_message = "Error in registrtion initiation request verification: #{e}"
      raise CustomError, :registration_verification_failed
    end

    # 3.4 Step 2: Discovery and openid Configuration
    openid_configuration = discover_openid_configuration(params['openid_configuration'])
    logger.debug(openid_configuration.to_yaml)

    tenant_uid = ''
    # scope can be @jwt_body['scope'] == 'reg' or @jwt_body['scope'] == 'reg-update'
    if @jwt_body['scope'] == 'reg-update' # update
      tool = RailsLti2Provider::Tool.where(uuid: openid_configuration['issuer']).where.not(tenant_id: 1).first
      tenant_uid = tool.tenant.uid unless tool.nil? # it is linked
    elsif RailsLti2Provider::Tool.exists?(uuid: openid_configuration['issuer'], tenant: tenant_uid) # new
      @error_message = "Issuer or Platform ID has already been registered for tenant '#{tenant_uid}'"
      raise CustomError, :tool_duplicated
    end
    tenant = RailsLti2Provider::Tenant.find_by(uid: tenant_uid)
    if tenant.nil?
      @error_message = "Tenant with uid = '#{tenant_uid}' does not exist"
      raise CustomError, :tenant_not_found
    end

    # 3.5 Step 3: Client Registration
    uri = URI(openid_configuration['registration_endpoint'])
    # 3.5.1 Issuer and OpenID Configuration URL Match
    # validate_issuer(jwt_body)

    # 3.5.2 Client Registration Request
    key_pair = new_rsa_keypair
    header = client_registration_request_header(params[:registration_token])
    body = client_registration_request_body(key_pair.token)
    body = body.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    request = Net::HTTP::Post.new(uri, header)
    request.body = body

    response = http.request(request)
    response = JSON.parse(response.body)

    # 3.6 Client Registration Response
    reg = {
      issuer: openid_configuration['issuer'],
      client_id: response['client_id'],
      key_set_url: openid_configuration['jwks_uri'],
      auth_token_url: openid_configuration['token_endpoint'],
      auth_login_url: openid_configuration['authorization_endpoint'],
      rsa_key_pair_id: key_pair.id,
      rsa_key_pair_token: key_pair.token,
      registration_token: params[:registration_token],
    }

    begin
      @tool = RailsLti2Provider::Tool.find_or_create_by(uuid: openid_configuration['issuer'], tenant: tenant)

      # old keys are removed when @jwt_body['scope'] == 'reg-update' after registration succeded
      if @jwt_body['scope'] == 'reg-update'
        key_pair_id = JSON.parse(@tool.tool_settings)['rsa_key_pair_id']
        key_pairs = RsaKeyPair.find(key_pair_id)
        key_pairs.destroy
      end

      # new keys are set
      @tool.shared_secret = response['client_id']
      @tool.tool_settings = reg.to_json.to_s
      @tool.lti_version = '1.3.0'
      @tool.status = 'enabled'
      @tool.save
    rescue StandardError => e
      # 3.6.2 Client Registration Error Response
      @error_message = "Error in registrtion when persisting: #{e}"
      raise CustomError, :registration_persitence_failed
    end

    # 3.6.1 Successful Registration
    logger.debug(@tool.to_json)
  end

  def discover_openid_configuration(url)
    JSON.parse(URI.parse(url).read)
  end
end
