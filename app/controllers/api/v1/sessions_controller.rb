# frozen_string_literal: true

class Api::V1::SessionsController < Api::V1::BaseController
  before_action :doorkeeper_authorize!

  def validate_launch
    app_launch = AppLaunch.find_by_nonce(params[:token])
    render(json: { token: params[:token], valid: false }.to_json) unless app_launch
    render(json: { token: params[:token], valid: true, message: JSON.parse(app_launch.message) }.to_json)
  end
end
