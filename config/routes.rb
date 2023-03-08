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

Rails.application.routes.draw do
  get '/health_check', to: 'health_check#show'
  get '/healthz', to: 'health_check#show'
  root 'application#index'

  # A monkey patch for supporting links coming from legacy LTI tools that hardcoded the launch under tool.
  get '(:tenant)/tool(.xml)', to: 'tool_profile#xml_config_legacy', app: ENV['DEFAULT_LTI_TOOL'] || 'default'
  post '(:tenant)/tool', to: 'message#basic_lti_launch_request_legacy', as: 'blti_launch_legacy', app: ENV['DEFAULT_LTI_TOOL'] || 'default'

  # rooms calls this api to validate launch from broker
  namespace :api do
    namespace :v1 do
      get 'users/:id', to: 'users#show', as: :users
      get 'user', to: 'users#show', as: :user
      get 'sessions/:token', to: 'sessions#validate_launch', as: :sessions
    end
  end

  # grades
  get 'grades/:grades_token/list', to: 'grades#grades_list', as: :grades_list
  post 'grades/:grades_token/change', to: 'grades#send_grades', as: :send_grades

  # registration (LMS -> broker)
  get 'registration/list', to: 'registration#list', as: :registration_list
  get 'registration/new', to: 'registration#new', as: :new_registration
  get 'registration/edit', to: 'registration#edit', as: :edit_registration
  post 'registration/submit', to: 'registration#submit', as: :submit_registration
  get 'registration/delete', to: 'registration#delete', as: :delete_registration

  # registration (broker -> rooms)
  use_doorkeeper do
    # Including 'skip_controllers :application' disables the controller for managing external applications
    #   [http://example.com/lti/oauth/applications]
    skip_controllers :applications unless ENV['DEVELOPER_MODE_ENABLED'] == 'true'
  end

  # lti 1.3 authenticate user through login
  get ':app/auth/login', to: 'auth#login'
  post ':app/auth/login', to: 'auth#login', as: 'openid_login'
  post ':app/messages/oblti', to: 'message#openid_launch_request', as: 'openid_launch'
  # requests from tool consumer go through this path
  get ':app/messages/blti', to: 'tool_profile#xml_config', app: ENV['DEFAULT_LTI_TOOL'] || 'default'
  post ':app/messages/blti', to: 'message#basic_lti_launch_request', as: 'blti_launch'

  # requests from xml_config go through these paths
  post ':app/messages/content-item', to: 'message#content_item_selection', as: 'content_item_request_launch'
  post ':app/messages/content-item', to: 'message#basic_lti_launch_request', as: 'content_item_launch'
  post ':app/messages/deep-link', to: 'message#deep_link', as: 'deep_link_request_launch'
  post ':app/messages/signed_content_item_request', to: 'message#signed_content_item_request'

  # LTI LAUNCH URL (responds to get and post)
  post ':app/launch', to: 'apps#launch', as: :app_launch

  match ':app/json_config/:temp_key_token', to: 'tool_profile#json_config', via: [:get, :post], as: 'json_config' # , :defaults => {:format => 'json'}

  # xml config and builder for lti 1.0/1.1
  get ':app/xml_config', to: 'tool_profile#xml_config', app: ENV['DEFAULT_LTI_TOOL'] || 'default', as: :xml_config
  get ':app/xml_builder', to: 'tool_profile#xml_builder', app: ENV['DEFAULT_LTI_TOOL'] || 'default', as: :xml_builder
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  get '/errors/:code', to: 'errors#index', as: :errors

  mount RailsLti2Provider::Engine => '/rails_lti2_provider'
end
