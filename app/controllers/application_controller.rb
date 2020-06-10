# frozen_string_literal: true

require 'uri'
require 'net/http'
require 'ims/lti'
require 'securerandom'
require 'faraday'
require 'oauthenticator'
require 'oauth'
require 'addressable/uri'
require 'oauth/request_proxy/action_controller_request'

class ApplicationController < ActionController::Base
  include AppsValidator

  protect_from_forgery with: :exception
  # CSRF stuff ^

  # verified oauth, etc
  # launch into lti application
  def app_launch
    # Make launch request to LTI-APP
    # A simplified version should be  doing the redirect whiout parameters, but stroing the launching request_parameters
    # so they can be returned on the session validation in the callback phase
    # redirect_to "#{lti_app_url(params[:app])}"

    # For the moment pass all the parameters ro the app
    parameters = params.to_unsafe_h
    @tool_uri = "#{lti_app_url(params[:app])}?#{parameters.except(:app, :controller, :action).to_query}"
    redirect_to(@tool_uri)
  end
end
