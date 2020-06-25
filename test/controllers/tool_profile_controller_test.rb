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
