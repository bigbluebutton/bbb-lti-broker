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

RSpec.describe(ToolProfileController, type: :controller) do
  describe 'GET :app/xml_config' do
    it 'gives an xml page when developer mode disabled' do
      ENV['DEVELOPER_MODE_ENABLED'] = 'false'
      get :xml_config, params: { app: 'default' }
      expect(response).to(have_http_status(:not_found))
    end

    it 'gives an xml page when developer mode enabled' do
      ENV['DEVELOPER_MODE_ENABLED'] = 'true'
      puts xml_config_path.to_yaml
      puts xml_config_url.to_yaml
      get :xml_config, params: { app: 'default' }
      expect(response).to(have_http_status(:success))

      # Element blti:title should never be empty
      doc = Nokogiri::XML(response.body)
      expect(doc.xpath('//blti:title').text.empty?).to(be(false))
    end
  end
end
