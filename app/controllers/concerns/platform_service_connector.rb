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

module PlatformServiceConnector
  include ActiveSupport::Concern

  # get access token for sending messages to the platform
  def access_token(registration, scopes)
    client_id = registration['client_id']
    auth_url = registration['auth_token_url']
    jwt_claim = {
      iss: client_id,
      sub: client_id,
      aud: auth_url,
      iat: Time.new.to_i - 5,
      exp: Time.new.to_i + 60,
      jti: "lti-service-token#{SecureRandom.hex}",
    }

    priv = File.read(registration['tool_private_key'])
    priv_key = OpenSSL::PKey::RSA.new(priv)

    jwt = JWT.encode(jwt_claim, priv_key, 'RS256')
    scopes.sort!

    auth_request = {
      grant_type: 'client_credentials',
      client_assertion_type: 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
      client_assertion: jwt,
      scope: scopes.map(&:inspect).join(' ').gsub('"', ''),
    }

    uri = URI.parse(auth_url)
    http = Net::HTTP.new(uri.host, uri.port)

    request = Net::HTTP::Post.new(uri.request_uri)
    request.set_form_data(auth_request)

    response = http.request(request)

    JSON.parse(response.body)['access_token']
  end

  # make request to platform
  def make_service_request(registration, scopes, method, url, body = nil, content_type = 'application/json', accept = 'application/json', token = nil)
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    token ||= access_token(registration, scopes)

    if method == 'POST'
      request = Net::HTTP::Post.new(uri.request_uri)
      request.content_type = content_type
    else
      request = Net::HTTP::Get.new(uri.request_uri)
    end

    request.add_field('Authorization', "Bearer #{token}")
    request['Accept'] = accept
    # request.add_field 'Accept', accept

    request.body = body

    http.request(request)
  end
end
