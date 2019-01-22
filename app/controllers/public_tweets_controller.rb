class PublicTweetsController < ApplicationController
  def load
    html = render_to_string partial: 'common/public_tweets'
    render json: {html: html}
  end
end
