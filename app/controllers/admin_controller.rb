class AdminController < ApplicationController
    before_action :verify_user
    before_action :verify_admin_of_user

    def home
        redirect_to admin_users_path
    end
    def users
    end

    def keys
        tools = RailsLti2Provider::Tool.all
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
        puts tool
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
end
