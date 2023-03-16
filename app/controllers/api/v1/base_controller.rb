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

class Api::V1::BaseController < ApplicationController
  before_action :print_parameters if Rails.configuration.developer_mode_enabled

  private

  def current_user
    return nil unless doorkeeper_token

    @current_user ||= User.find(doorkeeper_token.resource_owner_id)
  end

  def find_user
    return nil unless doorkeeper_token

    User.find(params[:id])
  end
end
