# frozen_string_literal: true

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

module CanvasExtensions
  PLATFORM = 'canvas.instructure.com'
  PLACEMENTS = [
    { key: :account_navigation, name: 'Account Navigation' },
    { key: :assignment_menu, name: 'Assignment Menu', message: %i[content_item_selection basic_lti_request] },
    { key: :assignment_selection, name: 'Assignment Selection', message: %i[content_item_selection_request basic_lti_request] },
    { key: :collaboration, name: 'Collaboration', message: %i[content_item_selection_request basic_lti_request] },
    { key: :course_assignments_menu, name: 'Course Assignments Menu', message: [:basic_lti_request] },
    { key: :course_home_sub_navigation, name: 'Course Home Sub Navigation' },
    { key: :course_navigation, name: 'Course Navigation' },
    { key: :course_settings_sub_navigation, name: 'Course Settings Sub Navigation' },
    { key: :discussion_topic_menu, name: 'Discussion Menu', message: %i[content_item_selection basic_lti_request] },
    { key: :editor_button, name: 'Editor Button', message: %i[content_item_selection_request basic_lti_request] },
    { key: :file_menu, name: 'File Menu', message: %i[content_item_selection basic_lti_request] },
    { key: :global_navigation, name: 'Global Navigation' },
    { key: :homework_submission, name: 'Homework Submission', message: %i[content_item_selection_request basic_lti_request] },
    { key: :link_selection, name: 'Link Selection', message: %i[content_item_selection_request basic_lti_request] },
    { key: :migration_selection, name: 'Migration Selection', message: %i[content_item_selection_request basic_lti_request] },
    { key: :module_menu, name: 'Module Menu', message: %i[content_item_selection basic_lti_request] },
    { key: :post_grades, name: 'Post Grades' },
    { key: :quiz_menu, name: 'Quiz Menu', message: %i[content_item_selection basic_lti_request] },
    { key: :similarity_detection, name: 'Similarity Detection', message: [:basic_lti_request] },
    { key: :tool_configuration, name: 'Tool Configuration' },
    { key: :user_navigation, name: 'User Navigation' },
    { key: :wiki_page_menu, name: 'Wiki Page Menu', message: %i[content_item_selection basic_lti_request] },
  ].freeze
end
