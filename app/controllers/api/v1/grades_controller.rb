require 'open-uri'
require 'net/http'
require 'date'

class Api::V1::GradesController < Api::V1::BaseController

  def send_grade
    if has_ags
      score_url = @jwt_body['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint']['lineitem']
      uri = URI.parse(score_url)
      uri.path << "/scores"
      
      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Post.new(uri.to_s)
      request.add_field 'Authorization', 'Bearer ' + access_token
      request.add_field 'Accept', 'application/json'

      request.content_type = 'application/vnd.ims.lis.v1.score+json'
      request.body = grade

      response = http.request(request)
    end
  end

    private
    # {
    #   :scoreGiven => 88,
    #   :scoreMaximum => 100,
    #   :activityProgress => 'Completed',
    #   :gradingProgress => 'FullyGraded',
    #   :timestamp => DateTime.now.iso8601,
    #   :userId => @external_user_id
    # }
    def grade 
      {
        :scoreGiven => params[:scoreGiven],
        :scoreMaximum => params[:scoreMaximum],
        :activityProgress => params[:activityProgress],
        :gradingProgress => params[:gradingProgress],
        :timestamp => params[:timestamp],
        :userId => params[:external_user_id]
      }.to_json
    end

    # check if platform offers assignment/grades services
    def has_ags
      ! @jwt_body['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint'].nil?
    end

    # check if platforms offers names and roles
    def has_nrps
      @jwt_body['https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice'].present? && @jwt_body['https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice']['context_memberships_url'].present?
    end

    def access_token
      scope = @jwt_body['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint']['lineitem']
      uri = URI.parse(scope)
      registration = RailsLti2Provider::Tool.find_by_issuer("#{uri.scheme}://#{uri.host}")
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

      priv = File.read(Rails.root.join('.ssh', 'id_rsa'))
      priv_key = OpenSSL::PKey::RSA.new(priv)
      
      jwt = JWT::encode jwt_claim, priv_key, 'RS256'
      @jwt_body['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint']['scope'].sort!

      auth_request = {
        :grant_type => 'client_credentials',
        :client_assertion_type => 'urn:ietf:params:oauth:client-assertion-type:jwt-bearer',
        :client_assertion => jwt,
        :scope => @jwt_body['https://purl.imsglobal.org/spec/lti-ags/claim/endpoint']['scope'].map(&:inspect).join(' ').gsub('"', '')
      }

      uri = URI.parse(auth_url)
      http = Net::HTTP.new(uri.host, uri.port)

      request = Net::HTTP::Post.new(uri.request_uri)
      request.set_form_data(auth_request)

      response = http.request(request)

      JSON.parse(response.body)['access_token']
    end
end