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
  include ActiveSupport::Concern

  def client_registration_request_header(token)
    {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'Authorization': "Bearer #{token}",
    }
  end

  def client_registration_request_body(key_token, app, app_name, app_desciption, app_icon_url)
    jwks_uri = registration_pub_keyset_url(key_token: key_token)

    tool = app || Rails.configuration.default_tool

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
        "custom_parameters": {},
        "claims": %w[iss sub name given_name family_name email nickname picture locale],
        "messages": [
          {
            "type": 'LtiDeepLinkingRequest',
            "target_link_uri": deep_link_request_launch_url(protocol: 'https'),
            "label": 'Add a tool',
            "icon_uri": app_icon_url || secure_url(lti_app_icon_url(tool)),
            "custom_parameters": {
              "context_id": '$Context.id',
            },
            # parameters supported by canvas only
            "placements": %w[link_selection],
            "roles": [],
          },
          # {
          #   "type": 'LtiResourceLinkRequest',
          #   "target_link_uri": openid_launch_url(protocol: 'https'),
          #   "label": "My #{tool.capitalize}",
          #   "icon_uri": app_icon_url || secure_url(lti_app_icon_url(tool)),
          #   "custom_parameters": {
          #     "context_id": '$Context.id',
          #   },
          #   # parameters supported by canvas only
          #   "placements": %w[link_selection course_navigation account_navigation],
          #   "roles": [],
          # },
        ],
      },
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

      logger.debug("jwt.header:\n#{jwt_header.inspect}")
      logger.debug("jwt.body:\n#{jwt_body.inspect}")
    rescue StandardError
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

  def validate_jwt_format(token)
    jwt_parts = token.split('.')
    raise CustomError, :invalid_id_token unless jwt_parts.length == 3

    jwt_parts
  end
end
