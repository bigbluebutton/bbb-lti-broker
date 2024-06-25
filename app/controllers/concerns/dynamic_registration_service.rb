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

module DynamicRegistrationService
  include ExceptionHandler
  include ActiveSupport::Concern

  def client_registration_request_header(token)
    {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': "Bearer #{token}",
    }
  end

  def client_registration_request_body(key_token, app, app_name, app_desciption, app_icon_url, app_label, message_types, custom_params)
    jwks_uri = registration_pub_keyset_url(key_token: key_token)

    tool = app || Rails.configuration.default_tool

    filtered_message_types = filter_valid_message_types(message_types)
    messages = filtered_message_types.map do |message_type|
      client_registration_request_body_message_type(message_type, tool, app_label, app_icon_url)
    end

    {
      "application_type": 'web',
      "response_types": ['id_token'],
      "grant_types": %w[implicit client_credentials],
      "initiate_login_uri": openid_login_url(protocol: 'https'),
      "redirect_uris":
          [openid_launch_url(protocol: 'https'),
           deep_link_request_launch_url(protocol: 'https'),],
      "client_name": app_name || t("apps.#{tool}.title"),
      "jwks_uri": jwks_uri,
      "logo_uri": app_icon_url || secure_url(lti_app_icon_url(tool)),
      "policy_uri": Rails.configuration.deployment_settings['policy_uri'],
      "tos_uri": Rails.configuration.deployment_settings['tos_uri'],
      "token_endpoint_auth_method": 'private_key_jwt',
      "contacts": [Rails.configuration.deployment_settings['contact_email']],
      "scope": 'https://purl.imsglobal.org/spec/lti-ags/scope/score https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly',
      "https://purl.imsglobal.org/spec/lti-tool-configuration": {
        "domain": URI.parse(openid_launch_url(protocol: 'https')).host,
        "description": app_desciption || t("apps.#{tool}.description"),
        "target_link_uri": openid_launch_url(protocol: 'https'),
        "custom_parameters": parse_custom_params(custom_params),
        "claims": %w[iss sub name given_name family_name email nickname picture locale],
        "messages": messages,
      },
    }
  end

  def client_registration_request_body_message_type(message_type, tool, label, icon_uri = nil)
    if message_type == 'LtiResourceLinkRequest'
      target_link_uri = openid_launch_url(protocol: 'https')
      placements = %w[link_selection course_navigation account_navigation]
    elsif message_type == 'LtiDeepLinkingRequest'
      target_link_uri = deep_link_request_launch_url(protocol: 'https')
      placements = %w[link_selection]
    else
      raise CustomError, :invalid_message_type
    end

    # the actual object to be returned.
    {
      "type": message_type,
      "target_link_uri": target_link_uri,
      "label": label || t("apps.#{tool}.title"),
      "icon_uri": icon_uri || secure_url(lti_app_icon_url(tool)),
      "custom_parameters": {},
      # parameters supported by canvas only
      "placements": placements,
      "roles": [],
    }
  end

  def validate_registration_initiation_request(token)
    # openid_configuration: the endpoint to the open id configuration to be used for this registration, encoded as per [RFC3986] Section 3.4.
    raise CustomError, :openid_configuration_not_found unless params.key?('openid_configuration')

    # registration_token (optional): the registration access token. If present, it must be used as the access token by the tool when making
    #                                the registration request to the registration endpoint exposed in the openid configuration.
    # raise CustomError, :registration_token_not_found unless params.key?('registration_token')

    begin
      jwt_parts = validate_jwt_format(token)
      jwt_header = JSON.parse(Base64.urlsafe_decode64(jwt_parts[0]))
      jwt_body = JSON.parse(Base64.urlsafe_decode64(jwt_parts[1]))

      logger.debug("JWT Header:\n#{JSON.pretty_generate(jwt_header)}")
      logger.debug("JWT Body:\n#{JSON.pretty_generate(jwt_body)}")
    rescue StandardError => e
      logger.error("Error occurred during JWT validation: #{e.message}")
      logger.error(e.backtrace.join("\n"))
      raise CustomError, :jwt_error
    end

    {
      header: jwt_header,
      body: jwt_body,
    }
  end

  # Generate a new RSA key pair and returnss the key_token as a reference.
  def new_rsa_keypair
    # Setting keys
    private_key = OpenSSL::PKey::RSA.generate(4096)
    public_key = private_key.public_key
    key_pair_token = Digest::MD5.hexdigest(SecureRandom.uuid)

    RsaKeyPair.create(
      private_key: private_key,
      public_key: public_key,
      token: key_pair_token
    )
  end

  private

  def filter_valid_message_types(message_types_str, default: 'LtiDeepLinkingRequest')
    valid_types = %w[LtiDeepLinkingRequest LtiResourceLinkRequest]
    message_types_str = (message_types_str || '').strip

    return [default] if message_types_str.empty?

    message_types = message_types_str.split(',').map(&:strip)
    valid_message_types = message_types.select { |type| valid_types.include?(type) }

    valid_message_types.empty? ? [default] : valid_message_types
  end

  def parse_custom_params(input_string)
    return {} if input_string.nil?

    key_value_pairs = input_string.split(',')

    result = {}

    key_value_pairs.each do |pair|
      # Skip the pair if it does not contain a colon
      next unless pair.presence && pair.include?(':')

      # Split the pair by colon to get the key and value
      key, value = pair.split(':')

      # Validate that both key and value are present
      next if key.nil? || value.nil? || key.strip.empty? || value.strip.empty?

      # Strip any leading or trailing whitespace from key and value
      key.strip!
      value.strip!

      # Add the valid key-value pair to the result hash
      result[key] = value
    end

    result
  end
end
