class StatusesController < ApplicationController
  include Logging
  include SearchesHelper

  before_action :set_twitter_user, only: %i(show)
  before_action only: %i(show) do
    create_search_log(action: :statuses)
  end

  # GET /statuses/:id
  def show
    @status_items = Kaminari.paginate_array(@searched_tw_user.statuses).page(params[:page]).per(100)
    @title = t('.title', user: @searched_tw_user.mention_name)
  end

  def keyword_timeline
    key = 'keyword_timeline'
    json = redis.fetch(key) do
      Bot.api_client.search(t('dictionary.app_name')).slice(0, 5).map { |t| t.to_hash }.to_json
    end
    tweets = JSON.load(json).slice(0, 5).map { |t| Hashie::Mash.new(t) }.map { |t| t.tweeted_at = t.created_at; t }
    html = render_to_string(partial: 'statuses/items', locals: {items: tweets})
    render json: {html: html}, status: 200
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    render nothing: true, status: 500
  end
end
