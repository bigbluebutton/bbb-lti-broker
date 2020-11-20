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
require 'rake'

RSpec.describe('rake tasks involving keys') do
  before do
    Rake.application.rake_require('tasks/db_keys')
    Rake::Task.define_task(:environment)

    @tenant = RailsLti2Provider::Tenant.create!(uid: 'tenant')
    @other_tenant = RailsLti2Provider::Tenant.create!(uid: 'other-tenant')
    @single_tenant_key = RailsLti2Provider::Tool.create!(uuid: 'single-key', shared_secret: 'secret', lti_version: 'LTI-1p0',
                                                         tool_settings: 'none', tenant: RailsLti2Provider::Tenant.create!(uid: ''))
    @multi_tenant_key = RailsLti2Provider::Tool.create!(uuid: 'multi-key', shared_secret: 'secret', lti_version: 'LTI-1p0',
                                                        tool_settings: 'none', tenant: @tenant)
  end
  describe 'calling db:keys' do
    it 'displays the existing keys' do
      expected_keys_text = "'single-key'='secret'\n'multi-key'='secret' for tenant 'tenant'\n"
      expect do
        Rake.application.invoke_task('db:keys:showall')
      end.to(output(expected_keys_text).to_stdout)
    end
    it 'and adding an key in single tenant' do
      Rake.application.invoke_task('db:keys:add[single-test-key, secret]')
    end
    it 'and adding an key in multi tenant' do
      Rake.application.invoke_task('db:keys:add[single-test-key, secret, tenant]')
    end
    it 'and updating an key in single tenant' do
      Rake.application.invoke_task('db:keys:update[single-key,secret-updated]')
    end
    it 'and updating an key in multi tenant' do
      Rake.application.invoke_task('db:keys:update[multi-key,secret-updated, other-tenant]')
    end
    it 'and deleting an key' do
      Rake.application.invoke_task("db:keys:delete[single-key]")
    end
  end
end
