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

class AppsController < ApplicationController
  # verified oauth, etc
  # launch into lti application
  def launch
    # Make launch request to LTI-APP
    lti_launch = RailsLti2Provider::LtiLaunch.find_by(nonce: params[:oauth_nonce])
    redirector = "#{lti_app_url(params[:app])}?#{{ launch_nonce: lti_launch.nonce }.to_query}"
    redirect_post(redirector, options: { authenticity_token: :auto })
  end
end
