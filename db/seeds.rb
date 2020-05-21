# frozen_string_literal: true

case Rails.env
when "development"
   default_key = 'key'
   default_secret = 'secret'

   default_tools = [
       {
         :name => 'default',
         :uid => 'key',
         :secret => 'secret',
         :redirect_uri => 'http://localhost:3000/apps/default/auth/bbbltibroker/callback'
       }
   ]

   unless RailsLti2Provider::Tool.find_by_uuid(default_key)
       RailsLti2Provider::Tool.create!(uuid: default_key, shared_secret: default_secret, lti_version: 'LTI-1p0', tool_settings:'none')
       default_tools.each do | tool |
         Doorkeeper::Application.create!(tool)
       end
   end
when "production"
end
