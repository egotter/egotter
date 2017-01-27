class SearchHistoriesController < ApplicationController
  layout false

  TTL = Rails.env.development? ? 1.second : 5.minutes

  def index
    @in_modal = params.has_key?(:in_modal) && params[:in_modal] == 'true' ? true : false
    html = redis.fetch("search_histories:#{current_user_id}:#{@in_modal}", ttl: TTL) do
      @search_histories = build_search_histories(current_user_id)
      render_to_string
    end

    render json: {html: html}, status: 200
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    render nothing: true, status: 500
  end

  private

  def build_search_histories(user_id)
    return [] if user_id == -1

    uids = BackgroundSearchLog.success_logs(user_id).pluck(:uid).unix_uniq.slice(0, 10)
    records = TwitterUser.where(uid: uids.uniq).map { |tu| [tu.uid.to_i, tu] }.to_h
    uids.map { |uid| records[uid.to_i] }.compact
  end
end
