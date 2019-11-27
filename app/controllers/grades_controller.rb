require 'open-uri'
require 'net/http'
require 'date'

class GradesController < ApplicationController
    include PlatformServiceConnector
    include PlatformMembersService
    include PlatformGradesService

    # for testing to see if grades made it through
    def grades_list
        send_grades
        if validate_grades_token?
            @grades = grades(@registration, @jwt_body['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint'])
            render 'grades/list'
        else
            render 'grades/failure'
        end
    end

    # rooms component should call this to set grades
    # temporarily hardcoded grades for every student
    def send_grades
        if validate_grades_token?
            token = access_token(@registration, @jwt_body['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint']['scope'])
            # can view members and send grades back
            if verify_permissions?
                score_url = platform_score_url(@jwt_body)
                platform_members(@registration, @jwt_body).each do |member|
                    response = send_grade_to_platform(
                        @registration, 
                        @jwt_body['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint']['scope'], 
                        score_url, 
                        platform_grade(member, 81, 100), 
                        token
                    )
                end
                # render 'grades/success'
            else
                # render json: @error.to_json
                # render 'grades/failure'
            end
        else
            # render json: @error.to_json
            # render 'grades/failure'
        end
    end
    
    private
    
        # does the tool have permission to get the list of students and send grades to the platform
        def verify_permissions?
            if platform_has_nrps?(@jwt_body) && platform_has_ags?(@jwt_body)
                return true
            else
                @error = {error: {key: 'bad_permissions', message: 'The tool does not have permission to send grades or access student list.'}}
                @error_message = 'The tool does not have permission to send grades or access student list.'
                return false
            end
        end
    
        # is the request to the broker for grades valid
        def validate_grades_token?
            return true if @registration.present? # already ran grades token validation

            launch = Rails.cache.read(params[:grades_token])
            if !launch
                @error = {error: {key: 'token_invalid', message: 'The token does not exist'} }
                @error_message = 'The token does not exist.'
                return false
            end
            if launch[:timestamp].to_i < 1.days.ago.to_i
                @error = {key: 'token_expired', message: 'The token has expired'}
                @error_message = 'The token has expired.'
                return false
            end
            lti_launch_nonce = launch[:lti_launch_nonce]

            lti_launch = RailsLti2Provider::LtiLaunch.find_by(nonce: lti_launch_nonce)

            unless lti_launch.present?
                @error_message = "The request has expired."
                return false
            end

            registration = RailsLti2Provider::Tool.find(lti_launch.tool_id)

            @jwt_body = lti_launch.jwt_body
            @registration = JSON.parse(registration.tool_settings)

            true
        end
end
