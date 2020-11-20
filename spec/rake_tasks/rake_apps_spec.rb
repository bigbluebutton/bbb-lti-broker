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

RSpec.describe('rake tasks involving apps') do
  before do
    Rake.application.rake_require('tasks/db_apps')
    Rake::Task.define_task(:environment)

    @app = Doorkeeper::Application.create!(name: 'test-app', uid: 'key', secret: 'secret', \
                                           redirect_uri: 'https://test.example.com', scopes: 'api')
  end
  describe 'calling db:app' do
    it 'displays the existing app' do
      appinfo ||= @app.attributes.select { |key, _value| %w[name uid secret redirect_uri].include?(key) }
      expect do
        Rake.application.invoke_task('db:apps:showall')
      end.to(output(appinfo.to_json + "\n").to_stdout)
    end
    it 'and adding an app' do
      Rake.application.invoke_task('db:apps:add[test-add-app,https://test.example.com,key-add,secret-add]')
    end
    it 'and updating an app' do
      Rake.application.invoke_task('db:apps:update[test-app,https://test.example.com,key-updated,secret-updated]')
    end
    it 'and deleting an app' do
      Rake.application.invoke_task('db:apps:delete[test-app]')
    end
  end
end
