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

module RoomsValidator
  include ActiveSupport::Concern

  def user_params(tc_instance_guid, params)
    {
      context: tc_instance_guid,
      uid: params['user_id'],
      full_name: params['custom_lis_person_name_full'] || params['lis_person_name_full'],
      first_name: params['custom_lis_person_name_given'] || params['lis_person_name_given'],
      last_name: params['custom_lis_person_name_family'] || params['lis_person_name_family'],
      last_accessed_at: DateTime.now,
    }
  end

  def tool_consumer_instance_guid(request_referrer, params)
    params['tool_consumer_instance_guid'] || URI.parse(request_referrer).host
  end

  def authorized_tools
    tools = Doorkeeper::Application.all.select('id, name, uid, secret, redirect_uri').to_a.map { |app| [app.name, app.attributes] }.to_h
    tools['default'] = {}
    tools
  end

  def lti_authorized_application
    params[:app] = params[:custom_app] unless params.key?(:app) || !params.key?(:custom_app)
    raise CustomError, :missing_app unless params.key?(:app)
    raise CustomError, :not_found unless params[:app] == 'default' || authorized_tools.key?(params[:app])
  end

  # Get doorkeeper entry for application name (unique) - gets entry with callback url for app (rooms, greenlight, etc)
  def lti_app(name)
    app = Doorkeeper::Application.where(name: name).first
    app.attributes.select { |key, _value| %w[name uid secret redirect_uri].include?(key) }
  end

  # names of all lti apps
  def lti_apps
    Doorkeeper::Application.all.pluck(:name)
  end

  def lti_icon(app_name)
    unless app_name == 'default'
      begin
        app = lti_app(app_name)
        uri = URI.parse(app['redirect_uri'])
        site = "#{uri.scheme}://#{uri.host}#{uri.port ? ':' + uri.port.to_s : ''}/"
        path = uri.path.split('/')
        path_base = (path[0].chomp(' ') == '' ? path[1] : path[0]).gsub('/', '') + '/'
      rescue StandardError
        # TODO: handle exception
        return
      end
    end
    "#{site}#{path_base + app_name + '/rooms/assets/icon.svg'}"
  end
end
