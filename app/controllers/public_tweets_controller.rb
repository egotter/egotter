class PublicTweetsController < ApplicationController
  def load
    html = render_to_string partial: 'common/public_tweets'
    render json: {html: html}, status: 200
  end
end
