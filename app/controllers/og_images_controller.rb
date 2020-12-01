class OgImagesController < ApplicationController

  TEMPLATE = <<~HTML
      <html>
      <meta http-equiv="refresh" content="<%= count %>;URL=<%= url %>">
      <head>
      </head>
    <body>
      Redirecting...
    </body>
      </html>
  HTML

  RETRIES_REGEXP = /\A[1-3]\z/

  before_action { valid_uid?(params[:uid]) }

  before_action do
    @retries = params[:retries].to_s

    if !@retries.empty? && !@retries.match?(RETRIES_REGEXP)
      head :not_found
    end
  end

  def show
    uid = params[:uid]
    twitter_user = TwitterUser.latest_by(uid: uid)

    if (url = twitter_user&.close_friends_og_image&.cdn_url)
      html = ERB.new(TEMPLATE).result_with_hash(count: 0, url: url)
      render html: html.html_safe, status: :found
    else
      retries = @retries.empty? ? 1 : @retries.to_i + 1
      url = og_image_path(uid: uid, retries: retries)
      html = ERB.new(TEMPLATE).result_with_hash(count: 5, url: url)
      render html: html.html_safe, status: :found
    end
  rescue => e
    head :not_found
  end
end

