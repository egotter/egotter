class BackgroundSearchLogsController < ApplicationController
  include Validation
  include PageCachesHelper

  before_action(only: %i(show)) { valid_uid?(params[:uid].to_i) }
  before_action(only: %i(show)) { searched_uid?(params[:uid].to_i) }

  def show
    uid = params[:uid].to_i
    log = BackgroundSearchLog.order(created_at: :desc).find_by(uid: uid, user_id: current_user_id)

    case
      when log.nil? || log.processing?
        render nothing: true, status: 202
      when log.finished?
        created_at = TwitterUser.with_friends.latest(uid).created_at.to_i
        render json: {message: log.message, created_at: created_at, hash: page_cache_token(created_at)}, status: 200
      when log.failed?
        render json: {reason: log.reason, message: log.message}, status: 500
      else
        render json: {reason: BackgroundSearchLog::SomethingError::MESSAGE}, status: 500
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    logger.info e.backtrace.take(10).join("\n")
    render json: {reason: BackgroundSearchLog::SomethingError::MESSAGE}, status: 500
  end
end
