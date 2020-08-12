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

class AppsController < ApplicationController
  # verified oauth, etc
  # launch into lti application
  def launch
    # Make launch request to LTI-APP
    redirector = "#{lti_app_url(params[:app])}?#{{ launch_nonce: app_launch.nonce }.to_query}"
    redirect_to(redirector)
  end

  private

  def app_launch
    tool = RailsLti2Provider::Tool.where(uuid: params[:oauth_consumer_key]).last
    lti_launch = RailsLti2Provider::LtiLaunch.find_by(nonce: params[:oauth_nonce])
    AppLaunch.find_or_create_by(nonce: lti_launch.nonce) do |launch|
      launch.update(tool_id: tool.id, message: standarized_message(lti_launch.message.to_json))
    end
  end

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
      message['launch_presentation_locale'] = message['unknown_params']['https://purl.imsglobal.org/spec/lti/claim/launch_presentation']['locale']
    end
    message.to_json
  end
end
