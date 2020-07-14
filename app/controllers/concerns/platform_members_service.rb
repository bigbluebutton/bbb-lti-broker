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

module PlatformMembersService
  include ActiveSupport::Concern

  # check if platforms offers names and roles
  def platform_has_nrps?(jwt_body)
    jwt_body['https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice'].present? &&
      jwt_body['https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice']['context_memberships_url'].present?
  end

  # get list of members enrolled in the course this room is in
  def platform_members(registration, jwt_body)
    next_page = jwt_body['https://purl.imsglobal.org/spec/lti-nrps/claim/namesroleservice']['context_memberships_url']
    external_members = []
    token = access_token(registration, ['https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly'])

    while next_page.present?

      response = make_service_request(
        registration,
        ['https://purl.imsglobal.org/spec/lti-nrps/scope/contextmembership.readonly'],
        'GET',
        next_page,
        nil,
        nil,
        'application/vnd.ims.lti-nrps.v2.membershipcontainer+json',
        token
      )

      if external_members.empty?
        external_members = JSON.parse(response.body)['members']
      else
        external_members += JSON.parse(response.body)['members']
      end

      next_page = false
      response.each_header do |key, value|
        next_page = value if key.capitalize.match(/Link/) && value.match(/rel=next/)
      end
    end
    external_members
  end
end
