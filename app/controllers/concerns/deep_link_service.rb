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

module DeepLinkService
  include ActiveSupport::Concern

  def deep_link_resource(url, custom_params, title)
    {
      'type' => 'ltiResourceLink',
      'title' => title,
      'url' => url,
      'presentation' => {
        'documentTarget' => 'window',
      },
      'custom' => custom_params,
    }
  end

  def deep_link_jwt_response(registration, jwt_header, jwt_body, resources)
    message = {
      'iss' => registration['client_id'],
      'aud' => [registration['issuer']],
      'exp' => Time.now.to_i + 600,
      'iat' => Time.now.to_i,
      'nonce' => "nonce#{SecureRandom.hex}",
      'https://purl.imsglobal.org/spec/lti/claim/deployment_id' => jwt_body['https://purl.imsglobal.org/spec/lti/claim/deployment_id'],
      'https://purl.imsglobal.org/spec/lti/claim/message_type' => 'LtiDeepLinkingResponse',
      'https://purl.imsglobal.org/spec/lti/claim/version' => '1.3.0',
      'https://purl.imsglobal.org/spec/lti-dl/claim/content_items' => resources,
      'https://purl.imsglobal.org/spec/lti-dl/claim/data' => jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']['data'],
    }

    message.each do |key, value|
      message[key] = '' if value.nil?
    end

    priv = File.read(registration['tool_private_key'])
    priv_key = OpenSSL::PKey::RSA.new(priv)

    JWT.encode(message, priv_key, 'RS256', kid: jwt_header['kid'])
  end
end
