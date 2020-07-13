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

# frozen_string_literal: true

case Rails.env
when 'development'
  default_key = 'key'
  default_secret = 'secret'

  default_tools = [
    {
      name: 'default',
      uid: 'key',
      secret: 'secret',
      redirect_uri: 'http://localhost:3000/apps/default/auth/bbbltibroker/callback',
    },
  ]

  unless RailsLti2Provider::Tool.find_by_uuid(default_key)
    RailsLti2Provider::Tool.create!(uuid: default_key, shared_secret: default_secret, lti_version: 'LTI-1p0', tool_settings: 'none')
    default_tools.each do |tool|
      Doorkeeper::Application.create!(tool)
    end
  end
  # when 'production'
end
