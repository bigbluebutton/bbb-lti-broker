require 'json'

class RegistrationController < ApplicationController
    # skip_before_action :verify_authenticity_token
    include PlatformValidator

    def list
        @registrations = RailsLti2Provider::Tool.where(lti_version: '1.3.0').pluck(:tool_settings)
        @registrations.map! { |reg|
            JSON.parse (reg)
        }
    end

    def new
    end

    def edit
        redirect_to registration_list_path unless params.has_key?('reg_id')
        @registration = lti_registration_params(params[:reg_id])
    end

    def submit
        return if params[:iss] == ""
        reg = {
            issuer: params[:iss],
            client_id: params[:client_id],
            key_set_url: params[:key_set_url],
            auth_token_url: params[:auth_token_url],
            auth_login_url: params[:auth_login_url],
            tool_private_key: params[:tool_private_key]
        }

        if params.has_key?('reg_id')
            if lti_registration_exists?(params[:reg_id])
                registration = lti_registration(params[:reg_id])
                registration.update(tool_settings: reg.to_json)
                registration.save
            end
        elsif ! lti_registration_exists?(params[:iss])
            RailsLti2Provider::Tool.create(
                uuid: params[:iss],
                shared_secret: "secret", # this isn't used in lti 1.3 - doesn't matter as long as it has a value
                tool_settings: reg.to_json,
                lti_version: '1.3.0'
            )
        end
        
        redirect_to registration_list_path
    end

    def delete
        reg = lti_registration(params[:reg_id])
        reg.delete
        redirect_to registration_list_path
    end
end