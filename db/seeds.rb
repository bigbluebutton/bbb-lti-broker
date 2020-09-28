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

tenant = RailsLti2Provider::Tenant.find_or_create_by!(uid: '')

case Rails.env
when 'development'
  default_keys = [
    {
      key: 'key',
      secret: 'secret',
    },
  ]

  default_keys.each do |default_key|
    unless RailsLti2Provider::Tool.find_by_uuid(default_key[:key])
      RailsLti2Provider::Tool.create!(uuid: default_key[:key], shared_secret: default_key[:secret], lti_version: 'LTI-1p0', tool_settings: 'none', tenant: tenant)
    end
  end

  default_tools = [
    {
      name: 'default',
      uid: 'key',
      secret: 'secret',
      redirect_uri: "https://#{Rails.configuration.url_host}/apps/default/auth/bbbltibroker/callback",
      scopes: 'api',
    },
  ]

  default_tools.each do |default_tool|
    Doorkeeper::Application.create!(default_tool) unless Doorkeeper::Application.find_by_name(default_tool[:name])
  end
  # when 'production'
end
