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
  get '(:tenant)/tool(.xml)', to: 'tool_profile#xml_config_legacy', app: Rails.configuration.default_tool
  post '(:tenant)/tool', to: 'message#basic_lti_launch_request_legacy', as: 'blti_launch_legacy', app: Rails.configuration.default_tool

  # tool registration (broker -> tool)
  use_doorkeeper do
    # Including 'skip_controllers :application' disables the controller for managing external applications
    #   [http://example.com/lti/oauth/applications]
    skip_controllers :applications unless ENV['DEVELOPER_MODE_ENABLED'] == 'true'
  end

  # tool launch (responds only to post)
  post ':app/launch', to: 'apps#launch', as: :app_launch

  # tool calls this api to validate launch from broker
  namespace :api do
    namespace :v1 do
      get 'users/:id', to: 'users#show', as: :users
      get 'user', to: 'users#show', as: :user
      get 'sessions/:token', to: 'sessions#validate_launch', as: :sessions
      get 'tenants/(:uid)', to: 'tenants#show', param: :uid
    end
  end

  # grades
  get 'grades/:grades_token/list', to: 'grades#grades_list', as: :grades_list
  post 'grades/:grades_token/change', to: 'grades#send_grades', as: :send_grades

  # lti 1.1
  # requests from tool consumer go through this path
  get ':app/messages/blti', to: 'tool_profile#xml_config', app: Rails.configuration.default_tool
  post ':app/messages/blti', to: 'message#basic_lti_launch_request', as: 'blti_launch'

  # xml config and builder (for Canvas)
  get ':app/xml_config', to: 'tool_profile#xml_config', app: Rails.configuration.default_tool, as: :xml_config
  get ':app/xml_builder', to: 'tool_profile#xml_builder', app: Rails.configuration.default_tool, as: :xml_builder

  # lti 1.3
  # authenticate user through login
  # e.g. https://HOSTNAME/lti/tool/auth/login sends launch to default app unless deep_link is used
  get 'tool/auth/login', to: 'auth#login'
  post 'tool/auth/login', to: 'auth#login', as: 'openid_login'
  post 'tool/messages/oblti', to: 'message#openid_launch_request', as: 'openid_launch'
  # requests from xml_config go through these paths
  post 'tool/messages/content-item', to: 'message#content_item_selection', as: 'content_item_request_launch'
  post 'tool/messages/content-item', to: 'message#basic_lti_launch_request', as: 'content_item_launch'
  post 'tool/messages/deep-link', to: 'message#deep_link', as: 'deep_link_request_launch'
  post 'tool/messages/signed_content_item_request', to: 'message#signed_content_item_request'
  # dynamic registration go through this paths
  get 'tool/registration', to: 'registration#dynamic', as: :registration
  get 'tool/registration/pub_keyset/(:key_token)', to: 'registration#pub_keyset', as: :registration_pub_keyset
  post 'tool/registration/link', to: 'registration#link', as: :registration_link

  match 'tool/json_config/:temp_key_token', to: 'tool_profile#json_config', via: [:get, :post], as: 'json_config' # , :defaults => {:format => 'json'}

  match 'errors/(:code)', to: 'errors#index', as: :errors, via: [:get, :post]

  mount RailsLti2Provider::Engine => '/rails_lti2_provider'
end
