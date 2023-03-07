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

require 'open-uri'
require 'net/http'
require 'date'

class GradesController < ApplicationController
  include PlatformServiceConnector
  include PlatformMembersService
  include PlatformGradesService

  before_action :print_parameters if Rails.configuration.developer_mode_enabled

  # For testing to see if grades made it through.
  def grades_list
    send_grades
    if validate_grades_token? && verify_permissions?
      @grades = grades(@registration, grades_claim_endpoint)
      render('grades/list')
    else
      render('grades/failure')
    end
  end

  # Send grades to the LMS
  # Temporarily hardcoded grades for every student
  def send_grades
    return unless validate_grades_token? && verify_permissions?

    token = access_token(@registration, grades_claim_endpoint['scope'])
    # can view members and send grades back
    score_url = platform_score_url(@jwt_body)
    platform_members(@registration, @jwt_body).each do |member|
      send_grade_to_platform(
        @registration,
        grades_claim_endpoint['scope'],
        score_url,
        platform_grade(member, 81, 100),
        token
      )
      # render 'grades/success'
    end
    # else
    # render json: @error.to_json
    # render 'grades/failure'
    # end
  end

  private

  # does the tool have permission to get the list of students and send grades to the platform
  def verify_permissions?
    if platform_has_nrps?(@jwt_body) && platform_has_ags?(@jwt_body)
      true
    else
      @error = { error: { key: 'bad_permissions', message: t('permission.nonrps') } }
      @error_message = t('permission.nonrps')
      false
    end
  end

  # is the request to the broker for grades valid
  def validate_grades_token?
    return true if @registration.present? # already ran grades token validation

    launch = Rails.cache.read(params[:grades_token])
    unless launch
      @error = { error: { key: 'token_invalid', message: t('error.invalid.token') } }
      @error_message = t('error.invalid.token')
      return false
    end
    if launch[:timestamp].to_i < 1.day.ago.to_i
      @error = { key: 'token_expired', message: t('error.expired.token') }
      @error_message = t('error.expired.token')
      return false
    end
    lti_launch_nonce = launch[:lti_launch_nonce]

    lti_launch = RailsLti2Provider::LtiLaunch.find_by(nonce: lti_launch_nonce)

    if lti_launch.blank?
      @error_message = t('error.expired.request')
      return false
    end

    registration = RailsLti2Provider::Tool.find(lti_launch.tool_id)

    @jwt_body = lti_launch.jwt_body
    @registration = JSON.parse(registration.tool_settings)

    true
  end

  def grades_claim_endpoint
    @jwt_body['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint']
  end
end
