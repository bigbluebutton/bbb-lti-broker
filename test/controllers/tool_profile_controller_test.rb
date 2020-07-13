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

# frozen_string_literal: true

require 'test_helper'

class ToolProfileControllerTest < ActionDispatch::IntegrationTest
  test 'responds with xml_config for default with no parameters when developer mode is true' do
    ENV['DEVELOPER_MODE_ENABLED'] = 'true'
    get xml_config_path('default')

    # Response must be successful
    assert_response(:success)

    # Element blti:title should never be empty
    doc = Nokogiri::XML(response.body)
    assert_not(doc.xpath('//blti:title').text.empty?)
  end

  test 'respond 404 for xml_config with developer mode is false' do
    ENV['DEVELOPER_MODE_ENABLED'] = 'false'
    get xml_config_path('default')

    # Response must be successful
    assert_response(:missing)
  end

  test 'respond 404 for xml_builder with developer mode is false' do
    ENV['DEVELOPER_MODE_ENABLED'] = 'false'
    get xml_builder_path('default')

    # Response must be successful
    assert_response(:missing)
  end
end
