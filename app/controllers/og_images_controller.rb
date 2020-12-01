class OgImagesController < ApplicationController

  before_action { valid_uid?(params[:uid]) }

  before_action do
    @retries = params[:retries].to_s

    if !@retries.empty? && !@retries.match?(/\A[1-3]\z/)
      head :not_found
    end
  end

  def show
    uid = params[:uid]
    twitter_user = TwitterUser.latest_by(uid: uid)

    if (url = twitter_user&.close_friends_og_image&.cdn_url)
      @count = 0
      @url = url
      render status: :found
    else
      @count = 5
      retries = @retries.empty? ? 1 : @retries.to_i + 1
      @url = og_image_path(uid: uid, retries: retries)
      render status: :found
    end
  rescue => e
    head :not_found
  end
end

