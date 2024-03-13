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

# required for LTI
require 'ims/lti'
# Used to validate oauth signatures
require 'oauth/request_proxy/action_controller_request'

class MessageController < ApplicationController
  include RailsLti2Provider::ControllerHelpers
  include ExceptionHandler
  include OpenIdAuthenticator
  include AppsValidator
  include LtiHelper
  include PlatformValidator
  include DeepLinkService

  before_action :print_parameters if Rails.configuration.developer_mode_enabled
  # skip rail default verify auth token - we use our own strategies
  skip_before_action :verify_authenticity_token
  # verify that the application belongs to us before doing anything with it
  before_action :lti_authorized_application, only: %i[basic_lti_launch_request basic_lti_launch_request_legacy]
  # validates message with oauth in rails lti2 provider gem
  before_action :lti_authentication, only: %i[basic_lti_launch_request basic_lti_launch_request_legacy]
  # validates message corresponds to a LTI request
  before_action :process_openid_message, only: %i[openid_launch_request deep_link]

  # fails lti_authentication in rails lti2 provider gem
  rescue_from RailsLti2Provider::LtiLaunch::Unauthorized do |ex|
    clean_up_openid_launch
    output = case ex.error
             when :invalid_key
               'The LTI key used is invalid'
             when :expired_key
               'The LTI key is expired'
             when :invalid_signature
               'The OAuth Signature was Invalid'
             when :invalid_nonce
               'The nonce has already been used'
             when :request_too_old
               'The request is too old'
             when :disabled_key
               'The key is disabled'
             else
               'Unknown Error'
             end
    @error = "Authentication failed with: #{output}"
    @message = IMS::LTI::Models::Messages::Message.generate(request.request_parameters)
    @header = SimpleOAuth::Header.new(:post, request.url, @message.post_params, consumer_key: @message.oauth_consumer_key,
                                                                                consumer_secret: lti_secret(@message.oauth_consumer_key), callback: 'about:blank')
    if request.request_parameters.key?('launch_presentation_return_url')
      launch_presentation_return_url = "#{request.request_parameters['launch_presentation_return_url']}&lti_errormsg=#{@error}"
      redirect_post(launch_presentation_return_url, options: { authenticity_token: :auto })
    else
      render(:basic_lti_launch_request, status: :ok)
    end
  end

  rescue_from ExceptionHandler::CustomError do |ex|
    clean_up_openid_launch
    @error = case ex.error
             when :disabled
               { code: '401',
                 key: t('error.http._401.code'),
                 message: t('error.app.disabled.message'),
                 suggestion: t('error.app.disabled.suggestion'),
                 status: '401', }
             else
               { code: '520',
                 key: t('error.http._520.code'),
                 message: t('error.http._520.message'),
                 suggestion: t('error.http._520.suggestion'),
                 status: '520', }
             end

    render 'errors/index'
  end

  rescue_from StandardError do |ex|
    logger.debug(ex)
    clean_up_openid_launch
    @error = { code: '520',
               key: t('error.http._520.code'),
               message: t('error.http._520.message'),
               suggestion: t('error.http._520.suggestion'),
               status: '520', }
    render 'errors/index'
  end

  # first touch point from tool consumer (moodle, canvas, etc) when using LTI 1.1
  def basic_lti_launch_request
    process_blti_message
    return if params[:app] == 'default'

    # Redirect to external application if configured
    Rails.cache.write(params[:oauth_nonce], message: @message, oauth: { consumer_key: params[:oauth_consumer_key], timestamp: params[:oauth_timestamp] })
    session[:user_id] = @current_user.id
    redirector = app_launch_path(params.to_unsafe_h.symbolize_keys)
    redirect_post(redirector, options: { authenticity_token: :auto })
  end

  # monkey patch for backward compatibility of old bbb-lti tools.
  # first touch point from tool consumer (moodle, canvas, etc) when using LTI 1.1 with a legacy URL.
  def basic_lti_launch_request_legacy
    # Inject the handler_legacy to the lti_launch.
    lti_launch = RailsLti2Provider::LtiLaunch.find_by(nonce: params[:oauth_nonce])
    post_params = lti_launch.message.post_params
    post_params['custom_handler_legacy'] = handler_legacy
    lti_message = IMS::LTI::Models::Messages::Message.generate(post_params)
    lti_launch.update(message: lti_message.post_params)

    # Bring back the launch to the regular flow.
    basic_lti_launch_request
  end

  # for /lti/:app/xml_builder enable placement for message type: content_item_selection_request
  # shows select content on tool configuration page in platform
  def content_item_selection
    process_blti_message
    @launch_url = blti_launch_url
    @update_url = content_item_request_launch_url
    @oauth_consumer_key = params[:oauth_consumer_key]
  end

  # first touch point from platform (moodle, canvas, etc) when using LTI 1.3
  def openid_launch_request
    ## The launch for LTI 1.3 sets params[:app] and redirectos to the corresponding app. The default tool is assigned if the parameter is not included.
    params[:app] ||= params[:custom_broker_app] || Rails.configuration.default_tool
    return if params[:app] == 'default' || params[:custom_broker_app] == 'default'

    params[:oauth_nonce] = @jwt_body['nonce']
    params[:oauth_consumer_key] = @jwt_body['iss']

    # Redirect to external application if configured.
    Rails.cache.write(params[:oauth_nonce], message: @message, oauth: { consumer_key: params[:oauth_consumer_key], timestamp: @jwt_body['exp'] })
    session[:user_id] = @current_user.id
    redirector = app_launch_path(params.to_unsafe_h.symbolize_keys)
    redirect_post(redirector, options: { authenticity_token: :auto })
  end

  # submit content item selection
  def signed_content_item_request
    launch_url = params.delete('return_url')
    tool = RailsLti2Provider::Tool.where(uuid: request.request_parameters[:oauth_consumer_key]).last
    message = IMS::LTI::Models::Messages::Message.generate(request.request_parameters)
    message.launch_url = launch_url
    @launch_params = { launch_url: message.launch_url, signed_params: message.signed_post_params(tool.shared_secret) }
    render('message/signed_content_item_form')
  end

  def deep_link
    @apps = []

    apps = lti_apps
    # Remove the default tool unless working in development mode.
    apps -= ['default'] unless Rails.configuration.developer_mode_enabled
    apps.each do |app|
      resource = deep_link_resource(openid_launch_url, "My #{app.singularize}", { 'broker_app': app })
      deep_link_jwt_message = deep_link_jwt_response(lti_registration_params(@jwt_body['iss']), @jwt_header, @jwt_body, [resource])
      @apps << { app_name: app, deep_link_jwt_message: deep_link_jwt_message }
    end

    # This is constant
    @deep_link_return_url = @jwt_body['https://purl.imsglobal.org/spec/lti-dl/claim/deep_linking_settings']['deep_link_return_url']
  end

  private

  # called by all requests to process the message first
  def process_blti_message
    @message = @lti_launch&.message || IMS::LTI::Models::Messages::Message.generate(request.request_parameters)
    tc_instance_guid = tool_consumer_instance_guid(request.referer, params)
    @header = SimpleOAuth::Header.new(:post, request.url, @message.post_params, consumer_key: @message.oauth_consumer_key,
                                                                                consumer_secret: lti_secret(@message.oauth_consumer_key), callback: 'about:blank')
    @current_user = User.find_or_create_by(context: tc_instance_guid, uid: params['user_id']) do |user|
      user.update(user_params(tc_instance_guid, params))
    end
  end

  # verify lti 1.3 launch
  def process_openid_message
    begin
      jwt = verify_openid_launch
    rescue StandardError => e
      logger.error("Error in openid launch verification: #{e}")
      raise e
    end

    @jwt_header = jwt[:header]
    @jwt_body = jwt[:body]

    tool = lti_registration(@jwt_body['iss'])
    tool.lti_launches.where('created_at < ?', 1.day.ago).delete_all
    @lti_launch = tool.lti_launches.create(nonce: @jwt_body['nonce'], message: @jwt_body.merge(@jwt_header))

    @message = IMS::LTI::Models::Messages::Message.generate(params)
    tc_instance_guid = tool_consumer_instance_guid(request.referer, params)
    @header = SimpleOAuth::Header.new(:post, request.url, @message.post_params, callback: 'about:blank')

    @current_user = User.find_or_create_by(context: tc_instance_guid, uid: @jwt_body['sub']) do |user|
      user.update(user_params(tc_instance_guid, @jwt_body))
    end
  end

  # Different legacy apps used different combinations of params to produce the handler or meetingID. On top of that
  # different consumers may come with differnt parameters or the data may be inconsistent. This is the reason why some
  # rules are needed.
  #   - param-xxx, it is a literal value of parameter xxx.
  #   - fqdn-yyy parses the host obtained from processing the value of parameter yyy as a URL.
  #   - | is a fallback in case the value found from the first pattern is empty.
  #
  #   E.g.
  #     konekti: 'param-tool_consumer_instance_guid|fqdn-ext_tc_profile_url,param-context_id,param-resource_link_id'
  #     bbb-lti 'param-resource_link_id,param-oauth_consumer_key' (default)
  #
  def handler_legacy
    # Hardcoded patterns to support Konekti launches.
    patterns = Rails.configuration.handler_legacy_patterns
    seed_string = ''
    patterns.split(',').each do |pattern|
      seed = ''
      if pattern.include?('|')
        fallbacks = pattern.split('|')
        fallbacks.each do |fallback|
          seed = seed_param(fallback)
          break unless seed.empty?
        end
      else
        seed = seed_param(pattern)
      end
      seed_string += seed
    end

    Digest::SHA1.hexdigest(seed_string)
  end

  # E.g. param-resource_link_id
  def seed_param(pattern)
    elements = pattern.split('-')
    return params[elements[1]] if elements[0] == 'param'
    return URI.parse(params[elements[1]]).host if elements[0] == 'fqdn'

    ''
  end
end
