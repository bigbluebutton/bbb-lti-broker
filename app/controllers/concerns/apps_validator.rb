# frozen_string_literal: true

module AppsValidator
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

  def lti_app_url(name)
    # The launch target is always in the form [schema://hostname/app_prefix/launch]. Since the callback endpoint
    # registered for the app in Doorkeeper is as [schema://hostname/app_prefix/auth/bbbltibroker/callback],
    # it is safe to remove the last 2 segments from the path.
    app = Doorkeeper::Application.where(name: name).first
    uri = URI.parse(app.redirect_uri)
    path = uri.path.split('/')
    path.delete_at(0)
    path = path.first(path.size - 3)
    "#{URI.join(uri, '/')}#{path.join('/')}/launch"
  end

  def lti_icon(app_name)
    return "http://#{request.host_with_port}/assets/icon.svg" if app_name == 'default'

    begin
      app = lti_app(app_name)
      uri = URI.parse(app['redirect_uri'])
      site = "#{uri.scheme}://#{uri.host}#{uri.port != 80 ? ':' + uri.port.to_s : ''}/"
      path = uri.path.split('/')
      path_base = (path[0].chomp(' ') == '' ? path[1] : path[0]).gsub('/', '') + '/'
    rescue StandardError
      # TODO: handle exception
      return
    end
    "#{site}#{path_base + app_name + '/assets/icon.svg'}"
  end
end
