# frozen_string_literal: true

class DeepLinkController < ApplicationController
  def callback
    jwt = params[:JWT]
    deep_link_return_url = params[:deep_link_return_url]

    render(json: { message: 'Deep Linking' }) && return if deep_link_return_url.nil?

    # Construct the URL with the JWT parameter
    redirect_url = URI(deep_link_return_url)
    query_params = Rack::Utils.parse_nested_query(redirect_url.query)
    query_params['JWT'] = jwt
    redirect_url.query = query_params.to_query

    redirector = redirect_url.to_s
    logger.debug("Redirecting to #{redirector}")

    redirect_post(redirector, options: { authenticity_token: :auto })
  end
end
