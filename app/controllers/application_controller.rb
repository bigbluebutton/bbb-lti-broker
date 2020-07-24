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

  @build_number = Rails.configuration.build_number
end
