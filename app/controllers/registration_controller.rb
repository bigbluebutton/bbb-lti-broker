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
  include AppsValidator
  include DynamicRegistrationService
  include ExceptionHandler
  include LtiHelper
  include OpenIdAuthenticator
  include PlatformValidator
  include RailsLti2Provider::ControllerHelpers

  before_action :print_parameters if Rails.configuration.developer_mode_enabled
  # skip rail default verify auth token - we use our own strategies
  skip_before_action :verify_authenticity_token
  # validates message corresponds to a LTI request
  before_action :process_registration_initiation_request, only: %i[dynamic]

  @error_message = ''
  @error_suggestion = ''

  rescue_from ExceptionHandler::CustomError, with: :handle_custom_error

  def dynamic
    # 3.7 Step 4: Registration Completed and Activation
    #   Once the registration is completed, successfully or not, the tool should notify the platform by sending an HTML5 Web Message
    #   [webmessaging] indicating the window may be closed. Depending on whether the platform opened the registration in an IFrame or
    #   a new tab, either window.parent or window.opener should be called.
    #
    #   The request received by the endpoint should include the following format:
    #
    #      /RELATIVE_URL_ROOT/tool/registration?app_name=APP_NAME&app_description=APP_DESCRIPTION&app_icon=APP_ICON&app_label=APP_LABEL&message_types=MESSAGE_TYPES&activation_code=ACTIVATION_CODE
    #
    #   All the parameters are optional, except for activation_code. The platform will use the activation_code to link the tool to the tenant.
    #   APP_NAME, APP_DESCRIPTION, APP_ICON, APP_LABEL are used to provide additional information about the tool to the platform.
    #   MESSAGE_TYPES parameter is a comma-separated list of message types that the tool supports.
    #
    #   The platform may use this information to display the tool in a catalog or to provide additional information to the user.
    #
    #   APP_NAME: The name of the tool (to be used for the Registration).
    #   APP_DESCRIPTION: A description of the tool.
    #   APP_ICON: A URL to an icon representing the tool.
    #   APP_LABEL: A label to be displayed to the user on each context.
    #   MESSAGE_TYPES: A comma-separated list of message types that the tool supports. The only messages supported are
    #   LtiDeepLinkingRequest (default) and LtiResourceLinkRequest.
    #   ACTIVATION_CODE: The activation code that was provided to the tool during the registration initiation request.
    #   The platform will use this code to link the tool to the tenant.
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
    logger.debug("rsa_key_pair.id= #{rsa_key_pair.id}\ntool= #{tool.to_json}\n")
    if tool.nil?
      logger.debug("Error pub_keyset\n Tool with rsa_key_pair_id=#{rsa_key_pair.id} was not found")
      render(json: JSON.pretty_generate({ error: { code: 404, message: 'not found' } }), status: :not_found) && return
    end
    tool_settings = JSON.parse(tool.tool_settings)
    if tool_settings['registration_token'].nil?
      logger.debug("Error pub_keyset\n The 'registration_token' was not found. This tool was registered manually.")
      render(json: JSON.pretty_generate({ error: { code: 404, message: 'not found' } }), status: :not_found) && return
    end

    reg_parts = tool_settings['registration_token'].split('.')
    reg_header = JSON.parse(Base64.urlsafe_decode64(reg_parts[0]))

    # prepare the pub_keyset
    json_pub_keyset = {}
    json_pub_keyset['keys'] = [
      {
        kty: 'RSA',
        e: Base64.urlsafe_encode64(public_key.e.to_s(2)).delete('='), # Exponent
        n: Base64.urlsafe_encode64(public_key.n.to_s(2)).delete('='), # Modulus
        kid: reg_header['kid'],
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
    # 3.3 Step 0: Request Verification
    verify_activation_code
    tenant = find_tenant_by_activation_code
    check_activation_code_expiration(tenant)

    # 3.3 Step 1: Registration Initiation Request
    begin
      registration_token = select_registration_token
      jwt = validate_registration_initiation_request(registration_token)
      @jwt_header = jwt[:header]
      @jwt_body = jwt[:body]
    rescue StandardError => e
      @error_message = "Error in registrtion initiation request verification: #{e}"
      raise CustomError, :registration_verification_failed
    end

    # 3.4 Step 2: Discovery and openid Configuration
    openid_configuration = discover_openid_configuration(params[:openid_configuration])
    logger.debug(openid_configuration.to_yaml)

    # scope can be @jwt_body['scope'] == 'reg' or @jwt_body['scope'] == 'reg-update'
    if @jwt_body['scope'] == 'reg-update' # update
      tool = RailsLti2Provider::Tool.where(uuid: openid_configuration['issuer']).where.not(tenant_id: 1).first
      unless tool.nil?
        tenant = tool.tenant
        # old keys are removed
        key_pair_id = JSON.parse(tool.tool_settings)['rsa_key_pair_id']
        RsaKeyPair.delete(key_pair_id)
      end
    elsif RailsLti2Provider::Tool.exists?(uuid: openid_configuration['issuer'], tenant: tenant) # new
      @error_message = "Issuer or Platform ID has already been registered for tenant '#{tenant.uid}'"
      raise CustomError, :tool_duplicated
    end

    # 3.5 Step 3: Client Registration
    uri = URI(openid_configuration['registration_endpoint'])
    # 3.5.1 Issuer and OpenID Configuration URL Match
    # validate_issuer(jwt_body)

    # 3.5.2 Client Registration Request
    key_pair = new_rsa_keypair
    header = client_registration_request_header(registration_token)
    logger.debug("registration_token header\n#{JSON.pretty_generate(header)}")
    body = client_registration_request_body(key_pair.token, params[:app], params[:app_name], params[:app_description], params[:app_icon], params[:app_label], params[:message_types],
                                            params[:custom_params])
    logger.debug("registration_token body\n#{JSON.pretty_generate(body)}")
    body = body.to_json

    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = (uri.scheme == 'https')
    request = Net::HTTP::Post.new(uri, header)
    request.body = body

    response = http.request(request)
    response = JSON.parse(response.body)
    logger.debug("response\n#{response}")

    # 3.6 Client Registration Response
    reg = {
      issuer: openid_configuration['issuer'],
      client_id: response['client_id'],
      key_set_url: openid_configuration['jwks_uri'],
      auth_token_url: openid_configuration['token_endpoint'],
      auth_login_url: openid_configuration['authorization_endpoint'],
      rsa_key_pair_id: key_pair.id,
      rsa_key_pair_token: key_pair.token,
      registration_token: registration_token,
    }
    logger.debug("reg to be attached to the tool\n#{reg}")

    tool_attributes = {
      shared_secret: response['client_id'],
      tool_settings: reg.to_json,
      lti_version: '1.3.0',
      status: 'enabled',
    }

    begin
      @tool = RailsLti2Provider::Tool.find_by(uuid: openid_configuration['issuer'], tenant: tenant)
      if @tool
        @tool.update(tool_attributes)
      else
        @tool = RailsLti2Provider::Tool.create(tool_attributes.merge(uuid: openid_configuration['issuer'], tenant: tenant))
        if @tool.persisted?
          logger.debug("Tool #{@tool.id} created...")
        else
          logger.debug("Tool creation failed: #{@tool.errors.full_messages.join(', ')}")
        end
      end
    rescue StandardError => e
      # 3.6.2 Client Registration Error Response
      @error_message = "Error in registrtion when persisting: #{e}"
      logger.debug("Error: #{@error_message}")
      raise CustomError, :registration_persitence_failed
    end

    # 3.6.1 Successful Registration
    logger.debug("Successfully registered #{@tool.to_json}")
  end

  def discover_openid_configuration(url)
    JSON.parse(URI.parse(url).read)
  end

  def select_registration_token
    if params[:registration_token].present?
      logger.debug('param registration_token included...')
      return params[:registration_token]
    end

    logger.debug('param registration_token NOT included taken from openid_configuration...')
    query_params = CGI.parse(URI.parse(params['openid_configuration']).query)
    query_params['registration_token'].first
  end

  def verify_activation_code
    return if params.key?(:activation_code)

    @error_message = 'activation_code parameter is required'
    raise CustomError, :activation_code_not_found
  end

  def find_tenant_by_activation_code
    tenant = RailsLti2Provider::Tenant.where("metadata ->> 'activation_code' = ?", params['activation_code']).first
    if tenant.nil?
      @error_message = "Tenant with activation_code = '#{params['activation_code']}' does not exist"
      raise CustomError, :tenant_not_found
    end

    tenant
  end

  def check_activation_code_expiration(tenant)
    activation_code_expire = tenant.metadata['activation_code_expire']
    return unless activation_code_expire.nil? || Time.zone.parse(activation_code_expire) <= Time.current

    @error_message = 'Activation code has expired'
    raise CustomError, :activation_code_expired
  end

  # Error handling
  ERROR_MAP = {
    tenant_not_found: '406',
    tool_duplicated: '406',
    activation_code_not_found: '406',
    activation_code_expired: '406',
    registration_verification_failed: '406',
    registration_persistence_failed: '406',
    invalid_message_type: '406',
    invalid_id_token: '406',
  }.freeze

  def handle_custom_error(exception)
    error_details = error_details_for(exception)
    log_error_details(exception, error_details)

    @error = error_details
    render('errors/index')
  end

  def error_details_for(exception)
    status = ERROR_MAP[exception.error] || '520'

    {
      code: status,
      key: t("error.http._#{status}.code"),
      message: error_message_for(exception.error, status),
      suggestion: error_suggestion_for(exception.error, status),
      status: status,
    }
  end

  def error_message_for(_, status)
    return @error_message if @error_message.present?

    t("error.http._#{status}.message")
  end

  def error_suggestion_for(_, status)
    @error_suggestion || t("error.http._#{status}.suggestion")
  end

  def log_error_details(exception, error_details)
    logger.error("Registration error: #{exception.error}:#{exception.message}")
    logger.error("Error details: #{error_details.to_yaml}")
  end
end
