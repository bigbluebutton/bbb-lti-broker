# frozen_string_literal: true

class Api::V1::SessionsController < Api::V1::BaseController
  before_action :doorkeeper_authorize!

  def validate_launch
    app_launch = AppLaunch.find_by_nonce(params[:token])

    response = { token: params[:token], valid: true, message: JSON.parse(app_launch.message) }
    render json: response.to_json
  end

end
