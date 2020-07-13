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

class Api::V1::SessionsController < Api::V1::BaseController
  before_action :doorkeeper_authorize!

  def validate_launch
    app_launch = AppLaunch.find_by_nonce(params[:token])
    render(json: { token: params[:token], valid: false }.to_json) unless app_launch
    render(json: { token: params[:token], valid: true, message: JSON.parse(app_launch.message) }.to_json)
  end
end
