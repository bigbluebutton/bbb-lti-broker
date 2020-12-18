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

RSpec.describe('rake tasks involving tenants') do
  before do
    Rake.application.rake_require('tasks/db_tenants')
    Rake::Task.define_task(:environment)
    @tenant = RailsLti2Provider::Tenant.create!(uid: 'tenant')
  end

  describe 'calling db:tenants' do
    it 'and displays the tenant' do
      tenant_text = /Tenant with uid 'tenant'/
      expect do
        Rake.application.invoke_task('db:tenants:showall')
      end.to(output(tenant_text).to_stdout)
    end
    it 'and adds a tenant' do
      Rake.application.invoke_task('db:tenants:add[test-tenant]')
    end
    it 'and deletes a tenant' do
      Rake.application.invoke_task('db:tenants:delete[tenant]')
    end
    it 'and deletes all tenants' do
      Rake.application.invoke_task('db:tenants:deleteall')
    end
  end
end
