require 'canvas_extensions'

class ToolProfileController < ApplicationController
    include ExceptionHandler
    include Converter
    include RoomsValidator

    before_action :lti_authorized_application, except: :json_config
    skip_before_action :verify_authenticity_token

    rescue_from CustomError do |ex|
        @error = 'Authorization failed with: ' + case ex.error
                                                  when :missing_app
                                                    'The App ID is not included'
                                                  when :not_found
                                                    'The App is not registered'
                                                  else
                                                    'Unknown Error'
                                                  end
        logger.info @error
    end

    # show xml builder for customization in tool consumer url
    def xml_builder
      @placements = CanvasExtensions::PLACEMENTS
    end

    def json_config
      # json_hash = JSON.parse(File.read(Rails.root.join('app', 'views', 'tool_profile', 'json_config.json')))
      # test_json_hash = JSON.parse(File.read(Rails.root.join('app', 'views', 'tool_profile', 'template_json_config.json')))

      # json_hash[:oidc_redirect_url] = openid_launch_url
      # json_hash[:oidc_initiation_url] = openid_login_url

      # pub = File.read(Rails.root.join('.ssh', 'id_rsa.pub'))
      # pub_key = OpenSSL::PKey::RSA.new(pub)
      # jwk = JWT::JWK.new(pub_key)
      
      # json_hash[:public_jwk] = jwk.export

      # json_hash['extensions'][0][:domain] = request.base_url
      # json_hash['extensions'][0][:tool_id] = Digest::MD5.hexdigest request.base_url
      # json_hash['extensions'][0]['settings'][:icon_url] = 'http://rooms.amy.blindside-dev.com:3401/apps/rooms/rooms/assets/icon.svg'

      @easy_config = {
        :tool_url => openid_launch_url,
        :public_key => File.read(Rails.root.join('.ssh', 'id_rsa.pub')),
        :initiate_login_url => openid_login_url,
        :redirection_uri => openid_launch_url
      }

      render json: JSON.pretty_generate(@easy_config)
    end

    def xml_config
        tc = IMS::LTI::Services::ToolConfig.new(:title => t("apps.#{params[:app]}.title"), :launch_url => blti_launch_url(:app => params[:app])) #"#{location}/#{year}/#{id}"
        tc.secure_launch_url = secure_url(tc.launch_url)
        tc.icon = lti_icon(params[:app])
        tc.secure_icon = secure_url(tc.icon)
        tc.description = t("apps.#{params[:app]}.description")

        if query_params = request.query_parameters
            platform = CanvasExtensions::PLATFORM
            tc.set_ext_param(platform, :selection_width, query_params[:selection_width])
            tc.set_ext_param(platform, :selection_height, query_params[:selection_height])
            tc.set_ext_param(platform, :privacy_level, 'public')
            tc.set_ext_param(platform, :text, t("apps.#{params[:app]}.title"))
            tc.set_ext_param(platform, :icon_url, tc.icon)
            tc.set_ext_param(platform, :domain, request.host_with_port)

            query_params[:custom_params].each { |_, v| tc.set_custom_param(v[:name].to_sym, v[:value]) } if query_params[:custom_params]
            query_params[:placements].each { |k, _| create_placement(tc, k.to_sym) } if query_params[:placements]
        end
        render xml: tc.to_xml(:indent => 2)
    end

    private

    # enable placement in xml_builder
    def create_placement(tc, placement_key)
        message_type = request.query_parameters["#{placement_key}_message_type"] || :basic_lti_request
        navigation_params = case message_type
                            when 'content_item_selection'
                              {url: content_item_request_launch_url, message_type: 'ContentItemSelection'}
                            when 'content_item_selection_request'
                              {url: content_item_request_launch_url, message_type: 'ContentItemSelectionRequest'}
                            else
                              {url: blti_launch_url}
                            end
    
        navigation_params[:icon_url] = tc.icon + "?#{placement_key}"
        navigation_params[:canvas_icon_class] = "icon-lti"
        navigation_params[:text] = t("apps.#{params[:app]}.title")
    
        tc.set_ext_param(CanvasExtensions::PLATFORM, placement_key, navigation_params)
    end
    
end