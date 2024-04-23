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

require 'canvas_extensions'

class ToolProfileController < ApplicationController
  include AppsValidator
  include ExceptionHandler
  include LtiHelper
  include TemporaryStore

  before_action :print_parameters if Rails.configuration.developer_mode_enabled
  before_action :lti_authorized_default_application, only: [:xml_builder, :xml_config]
  before_action :lti_authorized_application, only: :xml_builder
  skip_before_action :verify_authenticity_token

  rescue_from CustomError do |ex|
    output = case ex.error
             when :missing_app
               'The App ID is not included'
             when :not_found
               'The App is not registered'
             else
               'Unknown Error'
             end
    @error = "Authorization failed with: #{output}"
    logger.info(@error)
  end

  # show xml builder for customization in tool consumer url
  def xml_builder
    @placements = CanvasExtensions::PLACEMENTS
  end

  def json_config
    @keys = Rails.cache.read(params[:temp_key_token])

    @json_config = {}
    if !@keys
      @json_config = { error: t('registration.nokeymessage') }
    elsif @keys[:timestamp].to_i < 12.hours.ago.to_i
      @json_config = { error: t('registration.expkeymessage') }
    else
      @json_config = JSON.parse(File.read(Rails.root.join('app/views/tool_profile/json_config.json')))

      @json_config['target_link_uri'] = openid_launch_url
      @json_config['oidc_initiation_url'] = openid_login_url

      jwk = OpenSSL::PKey::RSA.new(read_temp_file(@keys[:public_key_path], delete: false)).to_jwk
      jwk['alg'] = 'RS256' unless jwk.key?('alg')
      jwk['use'] = 'sig' unless jwk.key?('use')

      @json_config['public_jwk'] = jwk

      @json_config['extensions'][0]['settings']['domain'] = request.base_url
      @json_config['extensions'][0]['settings']['tool_id'] = Digest::MD5.hexdigest(SecureRandom.uuid)
      @json_config['extensions'][0]['settings']['icon_url'] = lti_app_icon_url(params[:app])

      @json_config['extensions'][0]['settings']['placements'].each do |placement|
        placement['target_link_uri'] = openid_launch_url
        placement['icon_url'] = lti_app_icon_url(params[:app])
      end
    end
    render(json: JSON.pretty_generate(@json_config))
  end

  def xml_config
    render(xml: xml_config_tc(
      blti_launch_url(app: params[:app]).sub('https', 'http')
    ))
  end

  # This action is used only to support the old bbb application for backward compatibility
  def xml_config_legacy
    launch_url_params = { tenant: params[:tenant] } if params[:tenant]
    render(xml: xml_config_tc(
      blti_launch_legacy_url(launch_url_params).sub('https', 'http')
    ))
  end

  private

  # enable placement in xml_builder
  def create_placement(tc, placement_key)
    message_type = request.query_parameters["#{placement_key}_message_type"] || :basic_lti_request
    navigation_params = case message_type
                        when 'content_item_selection'
                          { url: content_item_request_launch_url, message_type: 'ContentItemSelection' }
                        when 'content_item_selection_request'
                          { url: content_item_request_launch_url, message_type: 'ContentItemSelectionRequest' }
                        else
                          { url: blti_launch_url }
                        end

    navigation_params[:icon_url] = tc.icon + "?#{placement_key}"
    navigation_params[:canvas_icon_class] = 'icon-lti'
    navigation_params[:text] = t("apps.#{params[:app]}.title")

    tc.set_ext_param(CanvasExtensions::PLATFORM, placement_key, navigation_params)
  end

  def xml_config_tc(launch_url)
    title = t("apps.#{params[:app]}.title", default: "#{params[:app].capitalize} #{t('apps.default.title')}")
    description = t("apps.#{params[:app]}.description", default: "#{t('apps.default.title')} provider powered by BBB LTI Broker.")
    tc = IMS::LTI::Services::ToolConfig.new(title: title, launch_url: launch_url) # "#{location}/#{year}/#{id}"
    tc.secure_launch_url = secure_url(tc.launch_url)
    tc.icon = lti_app_icon_url(params[:app])
    tc.secure_icon = secure_url(tc.icon)
    tc.description = description
    request.query_parameters.each { |key, value| tc.set_ext_param(CanvasExtensions::PLATFORM, key, value) }
    if params == request.query_parameters
      platform = CanvasExtensions::PLATFORM
      tc.set_ext_param(platform, :selection_width, params[:selection_width])
      tc.set_ext_param(platform, :selection_height, params[:selection_height])
      tc.set_ext_param(platform, :privacy_level, 'public')
      tc.set_ext_param(platform, :text, t("apps.#{params[:app]}.title"))
      tc.set_ext_param(platform, :icon_url, tc.icon)
      tc.set_ext_param(platform, :domain, request.host_with_port)

      params[:custom_params]&.each_value { |v| tc.set_custom_param(v[:name].to_sym, v[:value]) }
      params[:placements]&.each_key { |k| create_placement(tc, k.to_sym) }
    end
    tc.to_xml(indent: 2)
  end

  def lti_authorized_default_application
    return unless params[:app] == 'default' && ENV['DEVELOPER_MODE_ENABLED'] != 'true'

    render(file: Rails.root.join('public/404.html'), layout: false, status: :not_found)
  end
end
