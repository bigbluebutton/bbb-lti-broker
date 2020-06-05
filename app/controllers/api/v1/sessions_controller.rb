# frozen_string_literal: true

class Api::V1::SessionsController < Api::V1::BaseController
  before_action :doorkeeper_authorize!

  def show
    puts ">>>>>>>>>>> respond with info for authentication during calback phase"
    app_launch = AppLaunch.find_by_nonce(params[:nonce])
    puts session[:user_id]
    puts params[:nonce]
    puts params['redirect_uri']

    user = if params[:id]
             find_user
           else
             current_user
           end
    render json: user.as_json
  end
end
