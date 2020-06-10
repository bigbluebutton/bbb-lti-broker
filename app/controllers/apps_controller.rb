class AppsController < ApplicationController

  # verified oauth, etc
  # launch into lti application
  def launch
    # Make launch request to LTI-APP
    # A simplified version should be  doing the redirect whiout parameters, but stroing the launching request_parameters
    # so they can be returned on the session validation in the callback phase
    #redirect_to "#{lti_app_url(params[:app])}"

    # For the moment pass all the parameters ro the app
    # parameters = params.to_unsafe_h
    # redirector = "#{lti_app_url(params[:app])}?#{parameters.except(:app, :controller, :action).to_query}"
    redirector = "#{lti_app_url(params[:app])}?#{{:launch_nonce => app_launch.nonce}.to_query}"
    puts ">>>>> redirects to #{redirector}"
    redirect_to redirector
  end

  private

  def app_launch
    tool = RailsLti2Provider::Tool.where(uuid: params[:oauth_consumer_key]).last
    lti_launch = RailsLti2Provider::LtiLaunch.find_by(nonce: params[:oauth_nonce])
    AppLaunch.find_or_create_by(nonce: lti_launch.nonce) do |launch|
      launch.update(tool_id: tool.id, message: lti_launch.message.to_json)
    end
  end

end
