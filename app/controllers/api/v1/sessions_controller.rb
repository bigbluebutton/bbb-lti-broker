# frozen_string_literal: true

class Api::V1::SessionsController < Api::V1::BaseController
  before_action :doorkeeper_authorize!

  def show
    user = if params[:id]
             find_user
           else
             current_user
           end
    render(json: user.as_json)
  end
end
