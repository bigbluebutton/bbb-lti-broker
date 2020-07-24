# frozen_string_literal: true

require 'test_helper'
require 'nokogiri'

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
  test 'XML builder gives xml properties that are selected for cartridge link' do
    ENV['DEVELOPER_MODE_ENABLED'] = 'true'
    get xml_config_path('default') + '?selection_height=500&selection_width=500'
    page = Nokogiri::HTML.parse(@response.body)
    assert(page.xpath('//extensions/property'))
  end
end
