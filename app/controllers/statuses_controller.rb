class StatusesController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper

  before_action(only: %i(show)) { valid_uid?(params[:uid].to_i) }
  before_action(only: %i(show)) { existing_uid?(params[:uid].to_i) }
  before_action(only: %i(show)) { @searched_tw_user = TwitterUser.latest(params[:uid].to_i) }
  before_action(only: %i(show)) { authorized_search?(@searched_tw_user) }
  before_action only: %i(show) do
    push_referer
    create_search_log(action: :statuses)
  end

  # GET /statuses/:uid
  def show
    @statuses = Kaminari.paginate_array(@searched_tw_user.statuses.to_a).page(params[:page]).per(100)
    @title = t('.title', user: @searched_tw_user.mention_name)
  end

  # TODO remove later
  def keyword_timeline
    html = render_to_string(partial: 'twitter/tweet', collection: tweets_for(t('dictionary.app_name')), cached: true)
    render json: {html: html}, status: 200
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    render nothing: true, status: 500
  end
end
