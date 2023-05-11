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

module BbbLtiBroker
  module Helpers
    def string_to_hash(str)
      Hash[
        str.split(',').map do |pair|
          k, v = pair.split(':', 2)
          [k, v]
        end
      ]
    end

    def log_div(seed, num)
      div = seed
      (1..num).each do |_i|
        div += seed
      end
      logger.info(div)
    end

    def log_hash(hash, msg = nil)
      logger.debug(msg) if msg
      log_div('*', 100)
      hash.sort.map do |key, value|
        logger.debug("#{key}: " + value)
      end
      log_div('*', 100)
    end

    def secure_url(url)
      uri = URI.parse(url)
      uri.scheme = 'https'
      uri.to_s
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
        message['tool_consumer_instance_url'] = message['unknown_params']['https://purl.imsglobal.org/spec/lti/claim/tool_platform']['url']
        message['resource_link_id'] = message['unknown_params']['https://purl.imsglobal.org/spec/lti/claim/resource_link']['id']
        message['resource_link_title'] = message['unknown_params']['https://purl.imsglobal.org/spec/lti/claim/resource_link']['title']
        message['resource_link_description'] = message['unknown_params']['https://purl.imsglobal.org/spec/lti/claim/resource_link']['description']
        message['launch_presentation_locale'] = message['unknown_params']['https://purl.imsglobal.org/spec/lti/claim/launch_presentation']['locale']
      end
      custom_overrides(message).to_json
    end

    def user_params(tc_instance_guid, params)
      if params['user_id'].blank?
        params['user_id'] = params['sub']
        params['lis_person_name_full'] = params['name']
        params['lis_person_name_given'] = params['given_name']
        params['lis_person_name_family'] = params['family_name']
      end
      {
        context: tc_instance_guid,
        uid: params['user_id'],
        full_name: params['lis_person_name_full'],
        first_name: params['lis_person_name_given'],
        last_name: params['lis_person_name_family'],
        last_accessed_at: Time.current,
      }
    end

    ##
    # Overrides core parameters with custom parameters when following certain pattern.
    #
    # Core parameters may have to be overriden in order to make the applications behave differently
    # for that, the LTI link in the tool consumer would need to include a custom parameter in the form:
    #
    # custom_resource_link_id=static:"some value" -> resource_link_id="some value"
    # custom_resource_link_id=param:contenxt_id   -> resource_link_id=<value obtained from context_id>
    # custom_resource_link_id="another value"     -> resource_link_id=<no overriding is made>
    #
    def custom_overrides(message)
      custom_params = message['custom_params'].to_h
      custom_params.each do |key, value|
        custom_param = key.delete_prefix('custom_')
        pattern = value.split(':')
        message[custom_param] = pattern[1] if pattern[0] == 'static'
        message[custom_param] = message[pattern[1]] if pattern[0] == 'param'
      end
      message
    end
  end
end
