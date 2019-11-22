require 'open-uri'
require 'net/http'
require 'date'

class GradesController < ApplicationController
    def send_grades
        if validate_grades_token?
            @jwt_body = RailsLti2Provider::LtiLaunch.find_by(nonce: @lti_launch_nonce).jwt_body
        
            # can view members and send grades back
            if verify_permissions?
    
                score_url = @jwt_body['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint']['lineitem']
                uri = URI.parse(score_url)
                uri.path << "/scores"
        
                members.each do |member|
                    http = Net::HTTP.new(uri.host, uri.port)
                    request = Net::HTTP::Post.new(uri.to_s)
            
                    request.add_field 'Authorization', 'Bearer ' + access_token(@jwt_body['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint']['scope'])
                    request.add_field 'Accept', 'application/json'
            
                    request.content_type = 'application/vnd.ims.lis.v1.score+json'
                    request.body = grade(member)
            
                    response = http.request(request)
                end
                render 'grades/success'
            else
                # render json: @error.to_json
                render 'grades/failure'
            end
        else
            # render json: @error.to_json
            render 'grades/failure'
        end
    end
    
    private
    
        def verify_permissions?
            if has_nrps? && has_ags?
                return true
            else
                @error = {error: {key: 'bad_permissions', message: 'The tool does not have permission to send grades or access student list.'}}
                @error_message = 'The tool does not have permission to send grades or access student list.'
                return false
            end
        end
    
        def validate_grades_token?
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
            @lti_launch_nonce = launch[:lti_launch_nonce]
            true
        end
    
        def grade(member)
            {
                :scoreGiven => 100,
                :scoreMaximum => 100,
                :activityProgress => 'Completed',
                :gradingProgress => 'FullyGraded',
                :timestamp => DateTime.now.iso8601,
                :userId => member['user_id']
            }.to_json
        end
    
        # def grade 
        #   {
        #     :scoreGiven => params[:scoreGiven],
        #     :scoreMaximum => params[:scoreMaximum],
        #     :activityProgress => params[:activityProgress],
        #     :gradingProgress => params[:gradingProgress],
        #     :timestamp => params[:timestamp],
        #     :userId => params[:external_user_id]
        #   }.to_json
        # end
    
        # check if platform offers assignment/grades services
        def has_ags?
            ! @jwt_body['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint'].nil?
        end
    
        # check if platforms offers names and roles
        def has_nrps?
            @jwt_body['https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice'].present? && @jwt_body['https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice']['context_memberships_url'].present?
        end
    
        def members
            next_page = @jwt_body['https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice']['context_memberships_url']
            external_members = []
        
            while next_page.present?
                uri = URI.parse(next_page)
        
                http = http = Net::HTTP.new(uri.host, uri.port)
                request = Net::HTTP::Get.new(uri.to_s)
                request.add_field 'Authorization', 'Bearer ' + access_token(['https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly'])
                request.add_field 'Accept', 'application/vnd.ims.lti-nrps.v2.membershipcontainer+json'
        
                request.content_type = 'application/json'
                response = http.request(request)
    
                if external_members.empty? 
                external_members = JSON.parse(response.body)['members']
                else 
                external_members += JSON.parse(response.body)['members']
                end
        
                next_page = false
                puts "------------------------------- headers -------------------------------------"
                response.each_header do |key, value|
                # TODO: set next page to first match for preg "/^Link:.*<([^>])>; ?rel=\"next\"/i"
                    puts key + ": " + value
                end
            
                # render json: response.to_json
            end
    
            external_members
        end
    
        def access_token(scopes)
    
            registration = RailsLti2Provider::Tool.find(RailsLti2Provider::LtiLaunch.find_by(nonce: @lti_launch_nonce).tool_id)
            @registration = JSON.parse(registration.tool_settings)
        
            client_id = @registration['client_id']
            auth_url = @registration['auth_token_url']
            jwt_claim = {
                :iss => client_id,
                :sub => client_id,
                :aud => auth_url,
                :iat => Time.new().to_i - 5,
                :exp => Time.new().to_i + 60,
                :jti => "lti-service-token" << SecureRandom.hex
            }
    
            priv = File.read(@registration['tool_private_key'])
            priv_key = OpenSSL::PKey::RSA.new(priv)
            
            jwt = JWT::encode jwt_claim, priv_key, 'RS256'
            scopes.sort!
        
            auth_request = {
                :grant_type => 'client_credentials',
                :client_assertion_type => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
                :client_assertion => jwt,
                :scope => scopes.map(&:inspect).join(' ').gsub('"', '')
            }
    
            uri = URI.parse(auth_url)
            http = Net::HTTP.new(uri.host, uri.port)
        
            request = Net::HTTP::Post.new(uri.request_uri)
            request.set_form_data(auth_request)
        
            response = http.request(request)
        
            JSON.parse(response.body)['access_token']
        end
end
