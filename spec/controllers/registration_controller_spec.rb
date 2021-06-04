# frozen_string_literal: true

# BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
#
# Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
#
# This program is free software; you can redistribute it and/or modify it under the
# terms of the GNU Lesser General Public License as published by the Free Software
# Foundation; either version 3.0 of the License, or (at your option) any later
# version.
#
# BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
# PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public License along
# with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

require 'rails_helper'

RSpec.describe(RegistrationController, type: :controller) do
  before do
    ENV['DEVELOPER_MODE_ENABLED'] = 'true'
    tenant = RailsLti2Provider::Tenant.create!(uid: '')
    reg = {
      issuer: 'issuer',
      client_id: 'client_id',
      key_set_url: 'key_set_url',
      auth_token_url: 'auth_token_url',
      auth_login_url: 'auth_login_url',
    }
    @app = RailsLti2Provider::Tool.create!(
      uuid: 'issuer',
      shared_secret: 'client_id',
      tool_settings: reg.to_json,
      lti_version: '1.3.0',
      tenant: tenant
    )
  end

  describe 'GET registration/new' do
    it 'gives a successful response' do
      get :new
      expect(response).to(be_successful)
    end
  end

  describe 'POST registration/submit' do
    it 'adds another tool' do
      post :submit, params: {
        iss: 'test.com',
        client_id: 'test_secret',
        key_set_url: 'key.test.com',
        auth_token_url: 'auth-token.test.com',
        auth_login_url: 'auth-login.test.com',
      }
      expect(response).to(redirect_to(:registration_list))
    end
  end

  describe 'GET registration/list' do
    it 'gives a successful response' do
      get :list
      expect(response).to(be_successful)
    end

    it 'gives a proper list of all items' do
      get :list
      current_tools = RailsLti2Provider::Tool.where(lti_version: '1.3.0').pluck(:tool_settings)
      current_tools.map! do |reg|
        JSON.parse(reg)
      end
      expect(assigns(:registrations)).to(eq(current_tools))
    end
  end

  describe 'GET registration/edit' do
    it 'gives a successful response' do
      get :edit, params: { client_id: @app.shared_secret, reg_id: @app.uuid }
      expect(response).to(be_successful)
    end
    it 'edits an existing tool' do
      post :submit, params: {
        iss: 'test.com',
        client_id: 'test_secret',
        key_set_url: 'edit-key.test.com',
        auth_token_url: 'edit-auth-token.test.com',
        auth_login_url: 'edit-auth-login.test.com',
      }
      expect(response).to(redirect_to(:registration_list))
    end
  end
end
