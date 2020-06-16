# frozen_string_literal: true

require 'test_helper'

class ToolProfileControllerTest < ActionDispatch::IntegrationTest
  test 'responds with xml_config for default with no parameters' do
    get xml_config_path('default')

    # Response must be successful
    assert_response(:success)

    # Element blti:title should never be empty
    doc = Nokogiri::XML(response.body)
    assert(!doc.xpath("//blti:title").text.empty?)
  end
end
