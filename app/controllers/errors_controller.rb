# frozen_string_literal: true

#  BigBlueButton open source conferencing system - http://www.bigbluebutton.org/.
#
#  Copyright (c) 2018 BigBlueButton Inc. and by respective authors (see below).
#
#  This program is free software; you can redistribute it and/or modify it under the
#  terms of the GNU Lesser General Public License as published by the Free Software
#  Foundation; either version 3.0 of the License, or (at your option) any later
#  version.
#
#  BigBlueButton is distributed in the hope that it will be useful, but WITHOUT ANY
#  WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
#  PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.
#
#  You should have received a copy of the GNU Lesser General Public License along
#  with BigBlueButton; if not, see <http://www.gnu.org/licenses/>.

class ErrorsController < ApplicationController
  # skip rail default verify auth token - we use our own strategies
  skip_before_action :verify_authenticity_token

  def index
    code = params[:code] || '520'
    @error = { code: code,
               key: params[:key] || t("error.http._#{code}.code"),
               message: params[:message] || t("error.http._#{code}.message"),
               suggestion: params[:suggestion] || t("error.http._#{code}.suggestion"),
               status: code, }
    respond_to do |format|
      format.html { render(:index, layout: false, status: @error[:code]) }
      format.json { render(json: { error:  @error }, status: @error[:code]) }
    end
  end
end
