class BackgroundSearchLogsController < ApplicationController
  include Validation
  include PageCachesHelper

  before_action :basic_auth, only: :index
  before_action(only: %i(show)) { valid_uid?(params[:id].to_i) }

  def index
    status =
      if params.has_key?(:status) && params[:status] != ''
        params[:status] == 'true'
      else
        [true, false]
      end
    @logs = BackgroundSearchLog.where(status: status).order(created_at: :desc).limit(50)
    @status = status == [true, false] ? '' : status.to_s
  end

  # GET /background_search_logs/:id
  def show
    uid = params[:id].to_i
    unless Util::SearchedUidList.new(redis).exists?(uid)
      return render nothing: true, status: 400
    end

    user_id = current_user_id
    log = BackgroundSearchLog.order(created_at: :desc).find_by(uid: uid, user_id: user_id)

    case
      when log.nil? || log.processing?
        render nothing: true, status: 202
      when log.finished?
        created_at = TwitterUser.latest(uid).created_at.to_i
        render json: {message: log.message, created_at: created_at, hash: page_cache_token(created_at)}, status: 200
      when log.failed?
        render json: {reason: log.reason, message: log.message}, status: 500
      else
        render json: {reason: BackgroundSearchLog::SomethingError::MESSAGE}, status: 500
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    render json: {reason: BackgroundSearchLog::SomethingError::MESSAGE}, status: 500
  end
end
