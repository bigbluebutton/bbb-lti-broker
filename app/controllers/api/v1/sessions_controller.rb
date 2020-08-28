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
  before_action :doorkeeper_authorize!

  def validate_launch
    lti_launch = RailsLti2Provider::LtiLaunch.find_by_nonce(params[:token])
    render(json: { token: params[:token], valid: false }.to_json) unless lti_launch
    render(json: { token: params[:token], valid: true, message: JSON.parse(standarized_message(lti_launch.message.to_json)) }.to_json)
  end

  private

  def standarized_message(message_json)
    message = JSON.parse(message_json)
    if message['user_id'].blank?
      message['user_id'] = message['unknown_params']['sub']
      message['lis_person_name_full'] = message['unknown_params']['name']
      message['lis_person_name_given'] = message['unknown_params']['given_name']
      message['lis_person_name_family'] = message['unknown_params']['family_name']
      message['lis_person_contact_email_primary'] = message['unknown_params']['email']
      message['user_image'] = message['unknown_params']['picture']
      message['roles'] = message['unknown_params']['https://purl.imsglobal.org/spec/lti/claim/roles'].join(',')
      message['tool_consumer_instance_guid'] = message['unknown_params']['https://purl.imsglobal.org/spec/lti/claim/tool_platform']['guid']
      message['resource_link_id'] = message['unknown_params']['https://purl.imsglobal.org/spec/lti/claim/resource_link']['id']
      message['resource_link_title'] = message['unknown_params']['https://purl.imsglobal.org/spec/lti/claim/resource_link']['title']
      message['resource_link_description'] = message['unknown_params']['https://purl.imsglobal.org/spec/lti/claim/resource_link']['description']
      message['launch_presentation_locale'] = message['unknown_params']['https://purl.imsglobal.org/spec/lti/claim/launch_presentation']['locale']
    end
    message.to_json
  end
end
