module PlatformValidator
    include ActiveSupport::Concern

    def lti_secret(key, options = {})
        tool = RailsLti2Provider::Tool.find_by_uuid(key)
        return tool.shared_secret if tool
    end

    def lti_registration_exists?(iss, options = {})
        RailsLti2Provider::Tool.find_by_issuer(iss, options).present?
    end

    def lti_registration_params(iss, options = {})
        JSON.parse(lti_registration(iss, options).tool_settings) if lti_registration_exists?(iss, options)
    end

    def lti_registration(iss, options = {})
        RailsLti2Provider::Tool.find_by_issuer(iss, options) if lti_registration_exists?(iss, options)
    end
end