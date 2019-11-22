module OpenIdAuthenticator
    include ActiveSupport::Concern

    def verify_openid_launch
        # validate state
        raise CustomError.new(:state_not_found) unless params[:state] == cookies[:bbb_lti_state]
        raise CustomError.new(:missing_id_token) unless params.has_key?('id_token')

        # validate jwt format
        jwt_parts = params[:id_token].split(".")
        raise CustomError.new(:invalid_id_token) unless jwt_parts.length == 3
        jwt_header = JSON.parse(Base64.urlsafe_decode64(jwt_parts[0]))
        jwt_body = JSON.parse(Base64.urlsafe_decode64(jwt_parts[1]))

        # validate nonce
        raise CustomError.new(:invalid_nonce) unless jwt_body['nonce'] == Rails.cache.read("lti1p3_" << jwt_body['nonce'])[:nonce]

        # validate registration
        registration = RailsLti2Provider::Tool.find_by_issuer(jwt_body['iss'])
        raise CustomError.new(:not_registered) if registration.nil?
        reg = JSON.parse(registration.tool_settings)

        # validate jwt signature
        public_key_set = JSON.parse(open(reg['key_set_url']).string)
        jwk_json = public_key_set["keys"].find do |key|
        key['kid'] == jwt_header['kid'] && key['alg'] == jwt_header['alg']
        end
        jwk = JSON::JWK.new(jwk_json)
        
        # throws error if jwt is not valid
        JWT.decode params[:id_token], jwk.to_key, true, { algorithm: 'RS256' } 

        # validate message
        raise CustomError.new(:invalid_message_type) if jwt_body['https://purl.imsglobal.org/spec/lti/claim/message_type'].empty?

        clean_up_openid_launch

        params.merge! extract_old_param_format(jwt_body)

        # token is too big to store in cookie for rooms and we've already decoded it
        params.delete :id_token

        jwt_body
    end

    def clean_up_openid_launch
        cookies.delete(:bbb_lti_state)
    end

    def extract_old_param_format(jwt_body)
        p = {
        :resource_link_id => jwt_body['https://purl.imsglobal.org/spec/lti/claim/resource_link']['id'], # required
        :context_id => jwt_body['https://purl.imsglobal.org/spec/lti/claim/context']['id'], # recommended
        :launch_presentation_return_url => jwt_body['https://purl.imsglobal.org/spec/lti/claim/launch_presentation']['return_url'],
        :tool_consumer_instance_guid => jwt_body['https://purl.imsglobal.org/spec/lti/claim/tool_platform']['guid'],

        :user_id => jwt_body['https://purl.imsglobal.org/spec/lti/claim/context']['id'],
        :ext_user_username => jwt_body['https://purl.imsglobal.org/spec/lti/claim/ext']['user_username'],
        :ext_lms => jwt_body['https://purl.imsglobal.org/spec/lti/claim/ext']['lms'],
        :lis_person_sourcedid => jwt_body['https://purl.imsglobal.org/spec/lti/claim/lis']['person_sourcedid'],
        :lis_result_sourcedid => jwt_body['https://purl.imsglobal.org/spec/lti-bos/claim/basicoutcomesservice']['lis_result_sourcedid'],
        :lis_outcome_service_url => jwt_body['https://purl.imsglobal.org/spec/lti-bos/claim/basicoutcomesservice']['lis_outcome_service_url'],
        
        :context_label => jwt_body['https://purl.imsglobal.org/spec/lti/claim/context']['label'],
        :context_title => jwt_body['https://purl.imsglobal.org/spec/lti/claim/context']['title'],
        
        :lis_person_name_full => jwt_body['name'],
        :lis_person_name_given => jwt_body['given_name'],
        :lis_person_lis_person_name_family => jwt_body['family_name'],
        :lis_person_contact_email_primary => jwt_body['email'],
        :tool_consumer_info_product_family_code => jwt_body['https://purl.imsglobal.org/spec/lti/claim/tool_platform']['family_code'],
        :tool_consumer_info_version => jwt_body['https://purl.imsglobal.org/spec/lti/claim/tool_platform']['version'],
        :tool_consumer_instance_name => jwt_body['https://purl.imsglobal.org/spec/lti/claim/tool_platform']['name'],
        :tool_consumer_instance_description => jwt_body['https://purl.imsglobal.org/spec/lti/claim/tool_platform']['description'],
        :resource_link_title => jwt_body['https://purl.imsglobal.org/spec/lti/claim/resource_link']['title'],
        :resource_link_description => jwt_body['https://purl.imsglobal.org/spec/lti/claim/resource_link']['description'],

        :launch_presentation_locale => jwt_body['https://purl.imsglobal.org/spec/lti/claim/launch_presentation']['locale'],
        :launch_presentation_document_target => jwt_body['https://purl.imsglobal.org/spec/lti/claim/launch_presentation']['document_target'],
        
        :lti_version => jwt_body['https://purl.imsglobal.org/spec/lti/claim/version'],
        :roles => extract_old_roles(jwt_body)
        }
        p[:lti_message_type] = 'basic-lti-launch-request' if jwt_body['https://purl.imsglobal.org/spec/lti/claim/message_type'] == 'LtiResourceLinkRequest'
        p.each do |key, value|
            p[:"#{key}"] = "" if value.nil?
        end
        p
    end

    def extract_old_roles(jwt_body)
        roles = ""
        jwt_body['https://purl.imsglobal.org/spec/lti/claim/roles'].each do |r|
            roles << r.split('#', -1)[-1]
            roles << ',' unless r == jwt_body['https://purl.imsglobal.org/spec/lti/claim/roles'].last
        end
        roles
    end
end