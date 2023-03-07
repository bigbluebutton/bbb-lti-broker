# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.

# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).

# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.

# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

require 'ims/lti'
require 'securerandom'

class AuthController < ApplicationController
  include ExceptionHandler
  include PlatformValidator

  before_action :print_parameters if Rails.configuration.developer_mode_enabled
  skip_before_action :verify_authenticity_token
  before_action :validate_oidc_login

  # first touch point for lti 1.3
  # ensures platform is registered
  def login
    logger.info('AuthController: login')

    state = "state#{SecureRandom.hex}"

    cookies[state] = {
      value: state,
      expires: 1.year.from_now,
    }

    nonce = "nonce#{SecureRandom.hex}"
    Rails.cache.write("lti1p3_#{nonce}", nonce: nonce)

    auth_params = {
      scope: 'openid',
      response_type: 'id_token',
      response_mode: 'form_post',
      prompt: 'none',
      client_id: @registration['client_id'],
      redirect_uri: params[:target_link_uri],
      state: state,
      nonce: nonce,
      login_hint: params[:login_hint],
    }

    auth_params[:lti_message_hint] = params[:lti_message_hint] if params.key?(:lti_message_hint)

    aparams = URI.encode_www_form(auth_params)
    redirect_post("#{@registration['auth_login_url']}?#{aparams}", options: { authenticity_token: :auto })
  end

  private

  def validate_oidc_login
    raise CustomError, :could_not_find_issuer unless params.key?('iss')
    raise CustomError, :could_not_find_login_hint unless params.key?('login_hint')

    options = {}
    options['client_id'] = params[:client_id] if params.key?('client_id')

    unless lti_registration_exists?(params[:iss], options)
      render(file: Rails.root.join('public/500'), layout: false, status: :not_found)
      logger.error('ERROR: The app is not currently registered within the lti broker.')
      return
    end

    @registration = lti_registration_params(params[:iss], options)
  end
end
