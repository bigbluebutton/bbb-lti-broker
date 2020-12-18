class AdminController < ApplicationController
    before_action :verify_user
    before_action :verify_admin_of_user
    
    skip_before_action :verify_authenticity_token
    include PlatformValidator
    include AppsValidator
    include TemporaryStore

    def home
        redirect_to admin_users_path
    end
    def users
        @users = User.all
    end

    def delete_user
        if params[:username].nil?
            flash[:notice] = 'There is no username'
            redirect_to admin_users_path
            return
        end
        user = User.find_by(username: params[:username])
        if tool.nil?
            flash[:notice] = 'There is no existing user'
            redirect_to admin_users_path
            return
        end
        user.delete
        flash[:notice] = 'Successfully deleted!'
        redirect_to admin_users_path
    end

    def keys
        tools = RailsLti2Provider::Tool.all
        @apps = lti_apps
        @keys=[]
        tools.each do |tool|
            tenant = RailsLti2Provider::Tenant.find(tool.tenant_id).uid != "" ? RailsLti2Provider::Tenant.find(tool.tenant_id).uid : "-"
            @keys.append({"uuid" => tool.uuid, "shared_secret" => tool.shared_secret, "tenant" => tenant})
        end
    end

    def submit_key
        if params[:key] == '' || params[:secret] == ''
            flash[:notice] = 'There is already an existing key'
            redirect_to admin_keys_path
            return
        end
        key = params[:key]
        secret = params[:secret]
        tool = RailsLti2Provider::Tool.find_by(uuid: key)
        unless tool.nil?
            flash[:notice] = 'There is already an existing key'
            redirect_to admin_keys_path
            return
        end
        tenant = RailsLti2Provider::Tenant.find_by(uid: params[:tenant] || '')
        RailsLti2Provider::Tool.create!(uuid: key, shared_secret: secret, lti_version: 'LTI-1p0', tool_settings: 'none', tenant: tenant)
        redirect_to admin_keys_path, notice: 'Successfully created!'
    end

    def edit_key
        if params[:key] == '' || params[:secret] == ''
            flash[:notice] = 'There is already an existing key'
            redirect_to admin_keys_path
            return
        end
        key = params[:key]
        secret = params[:secret]
        tool = RailsLti2Provider::Tool.find_by(uuid: key)
        tenant = RailsLti2Provider::Tenant.find_by(uid: params[:tenant] || '')
        if tool.nil?
            flash[:notice] = 'There is no existing key'
            redirect_to admin_keys_path
            return
        end
        tool.update!(shared_secret: secret, tenant: tenant)
        flash[:notice] = 'Successfully updated!'
        redirect_to admin_keys_path
    end

    def delete_key
        if params[:key].nil?
            flash[:notice] = 'There is no key'
            redirect_to admin_keys_path
            return
        end
        
        tool = RailsLti2Provider::Tool.find_by(uuid: params[:key])
        if tool.nil?
            flash[:notice] = 'There is no existing key'
            redirect_to admin_keys_path
            return
        end
        tool.delete
        flash[:notice] = 'Successfully deleted!'
        redirect_to admin_keys_path
    end

    def deployments
        @registrations = RailsLti2Provider::Tool.where(lti_version: '1.3.0').pluck(:tool_settings)

        @app = ENV['DEFAULT_LTI_TOOL']
        @app ||= 'default' if ENV['DEVELOPER_MODE_ENABLED'] == 'true'
        @apps = lti_apps
        set_temp_keys
        set_starter_info
    end

    def submit_deployment
        return if params[:iss] == ''

        reg = {
        issuer: params[:iss],
        client_id: params[:client_id],
        key_set_url: params[:key_set_url],
        auth_token_url: params[:auth_token_url],
        auth_login_url: params[:auth_login_url],
        }

        if params.key?('private_key_path') && params.key?('public_key_path')
        key_dir = Digest::MD5.hexdigest(params[:iss] + params[:client_id])
        Dir.mkdir('.ssh/') unless Dir.exist?('.ssh/')
        Dir.mkdir('.ssh/' + key_dir) unless Dir.exist?('.ssh/' + key_dir)

        priv_key = read_temp_file(params[:private_key_path])
        pub_key = read_temp_file(params[:public_key_path])

        File.open(Rails.root.join(".ssh/#{key_dir}/priv_key"), 'w') do |f|
            f.puts(priv_key)
        end

        Rails.root.join('path/to')
        File.open(Rails.root.join(".ssh/#{key_dir}/pub_key"), 'w') do |f|
            f.puts(pub_key)
        end

        reg[:tool_private_key] = Rails.root.join(".ssh/#{key_dir}/priv_key") # "#{Rails.root}/.ssh/#{key_dir}/priv_key"
        end

        options = {}
        options['client_id'] = params[:client_id]

        registration = lti_registration(params[:reg_id], options) if params.key?('reg_id')
        unless registration.nil?
            reg[:tool_private_key] = lti_registration_params(params[:reg_id], options)['tool_private_key']
            registration.update(tool_settings: reg.to_json, shared_secret: params[:client_id])
            registration.save
            redirect_to(admin_deployments_path)
            return
        end

        tenant = RailsLti2Provider::Tenant.first
        unless tenant.nil?
        RailsLti2Provider::Tool.create!(
            uuid: params[:iss],
            shared_secret: params[:client_id],
            tool_settings: reg.to_json,
            lti_version: '1.3.0',
            tenant: tenant
        )
        end

        redirect_to(admin_deployments_path)
    end

    def delete_deployment
        options = {}
        options['client_id'] = params[:client_id] if params.key?('client_id')
        if lti_registration_exists?(params[:reg_id], options)
            reg = lti_registration(params[:reg_id], options)
            if lti_registration_params(params[:reg_id], options)['tool_private_key'].present?
                key_dir = Pathname.new(lti_registration_params(params[:reg_id])['tool_private_key']).parent.to_s
                FileUtils.remove_dir(key_dir, true) if Dir.exist?(key_dir)
            end
            reg.delete
        end
        redirect_to(admin_deployments_path)
    end

    def customization
    end

    private

    def verify_user
        redirect_to login_path unless current_user
    end

    def verify_admin_of_user
        redirect_to login_path unless current_user.admin?
    end

    def set_temp_keys
        private_key = OpenSSL::PKey::RSA.generate(4096)
        @jwk = JWT::JWK.new(private_key).export
        @jwk['alg'] = 'RS256' unless @jwk.key?('alg')
        @jwk['use'] = 'sig' unless @jwk.key?('use')
        @jwk = @jwk.to_json
    
        @public_key = private_key.public_key
    
        # keep temp files in scope so they are not deleted
        @public_key_file = store_temp_file('bbb-lti-rsa-pub-', @public_key.to_s)
        @private_key_file = store_temp_file('bbb-lti-rsa-pri-', private_key.to_s)
    
        # keep paths in cache for json configuration
        @temp_key_token = SecureRandom.hex
        Rails.cache.write(@temp_key_token, public_key_path: @public_key_file.path, private_key_path: @private_key_file.path, timestamp: Time.now.to_i)
      end
    
      def set_starter_info
        basic_launch_url = openid_launch_url(app: @app)
        deep_link_url = deep_link_request_launch_url(app: @app)
        @redirect_uri = basic_launch_url + "\n" + deep_link_url
      end
end
