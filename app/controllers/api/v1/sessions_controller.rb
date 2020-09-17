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

class Api::V1::SessionsController < Api::V1::BaseController
  include LtiHelper

  before_action :doorkeeper_authorize!

  def validate_launch
    lti_launch = RailsLti2Provider::LtiLaunch.find_by_nonce(params[:token])
    render(json: { token: params[:token], valid: false }.to_json) unless lti_launch
    tenant = lti_launch.tool.tenant.uid unless lti_launch.tool.tenant_id.nil?
    message = JSON.parse(standarized_message(lti_launch.message.to_json))
    render(json: { token: params[:token], valid: true, tenant: tenant || '', message: message }.to_json)
  end
end
