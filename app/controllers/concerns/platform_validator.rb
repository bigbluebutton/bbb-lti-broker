module PlatformValidator
    include ActiveSupport::Concern

    def lti_secret(key)
        tool = RailsLti2Provider::Tool.find_by_uuid(key)
        return tool.shared_secret if tool
    end

    def lti_registration_exists?(iss)
        RailsLti2Provider::Tool.find_by_issuer(iss).present?
    end

    def lti_registration_params(iss)
        JSON.parse(lti_registration(iss).tool_settings) if lti_registration_exists?(iss)
    end

    def lti_registration(iss)
        RailsLti2Provider::Tool.find_by_issuer(iss) if lti_registration_exists?(iss)
    end
end