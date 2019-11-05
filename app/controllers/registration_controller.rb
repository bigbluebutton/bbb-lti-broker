class RegistrationController < ApplicationController
    include RailsLti2Provider::ControllerHelpers
  
    before_action :registration_request, only: :register
    before_action :lti_authentication, only: :register, if: :update_registration?
    protect_from_forgery except: :save_capabilities
    after_action :disable_xframe_header
  
    def register
      #tool_setting_service = %w(LtiLink.custom.url ToolProxyBinding.custom.url ToolProxy.custom.url)
      filter_out = [
          IMS::LTI::Models::Messages::BasicLTILaunchRequest::MESSAGE_TYPE,
          IMS::LTI::Models::Messages::ToolProxyUpdateRequest::MESSAGE_TYPE
      ]
      tcp = @registration.tool_consumer_profile
      @capabilities = tcp.capability_offered.each_with_object({placements: [], parameters: []}) do |cap, hash|
        unless filter_out.include? cap
          if cap =~ /Canvas\.placements\.(.*$)/
            hash[:placements] << $1
          else
            hash[:parameters] << cap
          end
        end
      end
      tcp_url = tcp.id || @registration.registration_request.tc_profile_url
      @services_offered = tcp.services_offered.each_with_object([]) do |service, col|
        unless service.id.include? 'ToolProxy.collection'
          name = service.id.split(':').last.split('#').last
          col << {
              name: name,
              service: "#{tcp_url}##{name}",
              actions: service.actions
          }
        end
      end
  
    end
  
    def save_capabilities
      registration = RailsLti2Provider::Registration.find(params["reg_id"])
      parameters = params['variable_parameters'] ? params['variable_parameters'].select { |_, v| v['enabled'] } : {}
      placements = params['placements'] ? params['placements'].select { |_, v| v['enabled'] } : {}
      services = params['service'] ? params['service'].select { |_, v| v['enabled'] } : {}
      tool_services = services.each do |_, v|
        #The JSON could be a single element or an array, we want to force it to an array
        actions = [*JSON.parse("{\"a\":#{v['actions']}}")['a']]
        IMS::LTI::Models::RestServiceProfile.new(service: v['id'], action: actions)
      end
      tool_settings = (params['tool_settings'].present? && JSON.parse(params['tool_settings'])) || nil
      tool_proxy = registration.tool_proxy
      tool_profile = tool_proxy.tool_profile
      add_update_registration_handler!(registration, tool_profile)
      tool_proxy.security_contract.tool_service = tool_services if tool_services.present?
      rh = tool_profile.resource_handler.first
      mh = rh.message.first
      mh.parameter = parameters.each { |var, val| IMS::LTI::Models::Parameter.new(name: val['name'], variable: var) }
      rh.ext_placements = placements.keys
      mh.enabled_capability = placements.keys
      tool_proxy.custom = tool_settings if tool_settings
  
      redirect_to(submit_proxy_path(:registration_uuid => registration.id))
    end
  
    def submit_proxy
        registration = RailsLti2Provider::Registration.find(params[:registration_uuid])
        begin
          response = register_proxy(registration)
        rescue IMS::LTI::Errors::ToolProxyRegistrationError
          response = {
              return_url: registration.registration_request.launch_presentation_return_url,
              status: 'error',
              message: "Failed to create a tool proxy",
          }
        end
        redirect_to_consumer(response)
    #   begin
    #     registration = RailsLti2Provider::Registration.find(params[:registration_uuid])
    #     redirect_to_consumer(register_proxy(registration))
    #   rescue IMS::LTI::Errors::ToolProxyRegistrationError => e
    #     @error = {
    #         tool_proxy_guid: registration.tool_proxy.tool_proxy_guid,
    #         response_status: e.response_status,
    #         response_body: e.response_body
    #     }
    #   end
    end
  
  
    def add_update_registration_handler!(registration, tool_profile)
      if (registration.tool_consumer_profile.capability_offered.include?(IMS::LTI::Models::Messages::ToolProxyUpdateRequest::MESSAGE_TYPE))
        rereg_mh = IMS::LTI::Models::MessageHandler.new(
            message_type: IMS::LTI::Models::Messages::ToolProxyUpdateRequest::MESSAGE_TYPE,
            path: tool_update_registration_path
        )
        tool_profile.message = [rereg_mh]
      end
    end
  
    protected
  
    def update_registration?
      params[:lti_message_type] ==  IMS::LTI::Models::Messages::ToolProxyUpdateRequest::MESSAGE_TYPE
    end
  
  end
  