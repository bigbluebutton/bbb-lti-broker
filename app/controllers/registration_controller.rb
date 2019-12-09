require 'json'
require 'pathname'

class RegistrationController < ApplicationController
    skip_before_action :verify_authenticity_token
    include PlatformValidator
    include RoomsValidator
    include TemporaryStore

    def list
        @registrations = RailsLti2Provider::Tool.where(lti_version: '1.3.0').pluck(:tool_settings)
        @registrations.map! { |reg|
            JSON.parse (reg)
        }
    end

    # only available if developer mode is on
    # production - use rails task
    def new
        @app = ENV['DEFAULT_LTI_TOOL'] || 'default'
        @apps = lti_apps
        set_temp_keys
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
        }

        if params.has_key?('private_key_path') && params.has_key?('public_key_path')
            key_dir = Digest::MD5.hexdigest params[:iss] + params[:client_id]
            Dir.mkdir('.ssh/' + key_dir) unless Dir.exist?('.ssh/' + key_dir)

            priv_key = read_temp_file(params[:private_key_path])
            pub_key = read_temp_file(params[:public_key_path])

            File.open(File.join(Rails.root, '.ssh', key_dir, 'priv_key'), "w") do |f|
                f.puts priv_key
            end

            File.open(File.join(Rails.root, '.ssh', key_dir, 'pub_key'), "w") do |f|
                f.puts pub_key
            end

            reg[:tool_private_key] = "#{Rails.root}/.ssh/#{key_dir}/priv_key"
        end
        
        if params.has_key?('reg_id')
            if lti_registration_exists?(params[:reg_id])
                registration = lti_registration(params[:reg_id])
                registration.update(tool_settings: reg.to_json, shared_secret: params[:client_id])
                registration.save
            end
        # elsif ! lti_registration_exists?(params[:iss])
        else
            RailsLti2Provider::Tool.create!(
                uuid: params[:iss],
                shared_secret: params[:client_id],
                tool_settings: reg.to_json,
                lti_version: '1.3.0'
            )
        end
        
        redirect_to registration_list_path
    end

    def delete
        reg = lti_registration(params[:reg_id])
        if lti_registration_params(params[:reg_id])['tool_private_key'].present?
            key_dir = Pathname.new(lti_registration_params(params[:reg_id])['tool_private_key']).parent.to_s
            if Dir.exist? key_dir
                FileUtils.remove_dir(key_dir, true)
            end
        end
        reg.delete
        redirect_to registration_list_path
    end

    private

    def set_temp_keys
        private_key = OpenSSL::PKey::RSA.generate 4096
        @jwk = JWT::JWK.new(private_key).export
        @jwk["alg"] = "RS256" unless @jwk.has_key? "alg"
        @jwk["use"] = "sig" unless @jwk.has_key? "use"
        @jwk = @jwk.to_json

        @public_key = private_key.public_key
        
        # keep temp files in scope so they are not deleted
        @public_key_file = store_temp_file("bbb-lti-rsa-pub-", @public_key.to_s)
        @private_key_file = store_temp_file("bbb-lti-rsa-pri-", private_key.to_s)

        @public_key_path = @public_key_file.path
        @private_key_path = @private_key_file.path
    end
end