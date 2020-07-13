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
<<<<<<< HEAD

  test 'XML builder gives xml properties that are selected for cartridge link' do
    ENV['DEVELOPER_MODE_ENABLED'] = 'true'
    get xml_config_path('default') + "?assignment_menu_message_type=content_item_selection&assignment_selection_message_type=content_item_selection_request&collaboration_message_type=content_item_selection_request&course_assignments_menu_message_type=basic_lti_request&discussion_topic_menu_message_type=content_item_selection&editor_button_message_type=content_item_selection_request&file_menu_message_type=content_item_selection&homework_submission_message_type=content_item_selection_request&link_selection_message_type=content_item_selection_request&migration_selection_message_type=content_item_selection_request&module_menu_message_type=content_item_selection&quiz_menu_message_type=content_item_selection&similarity_detection_message_type=basic_lti_request&wiki_page_menu_message_type=content_item_selection&selection_height=500&selection_width=500"
    page = Nokogiri::HTML.parse(@response.body)
    assert(page.xpath('//extensions/property'))
  end
=======
>>>>>>> 779bcfd71e5bbe2284c431f24e4870829118bb33
end
