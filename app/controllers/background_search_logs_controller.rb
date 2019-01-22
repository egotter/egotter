class BackgroundSearchLogsController < ApplicationController
  include Concerns::Validation

  before_action(only: %i(show)) { valid_uid? }
  before_action(only: %i(show)) { searched_uid?(params[:uid].to_i) }

  def show
    uid = params[:uid].to_i
    log = BackgroundSearchLog.order(created_at: :desc).find_by(uid: uid, user_id: current_user_id)

    case
      when log.nil? || log.processing?
        render nothing: true, status: 202
      when log.finished?
        twitter_user = TwitterUser.latest(uid)
        if twitter_user
          created_at = twitter_user.created_at.to_i
          render json: {message: log.message, created_at: created_at}
        else
          logger.warn "#{self.class}##{__method__}: not found #{current_user_id} #{uid} #{log.inspect}"
          render json: {reason: BackgroundSearchLog::SomethingError::MESSAGE}, status: 500
        end
      when log.failed?
        render json: {reason: log.reason, message: log.message}, status: 500
      else
        render json: {reason: BackgroundSearchLog::SomethingError::MESSAGE}, status: 500
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{current_user_id} #{uid} #{request.referer}"
    logger.info e.backtrace.take(10).join("\n")
    render json: {reason: BackgroundSearchLog::SomethingError::MESSAGE}, status: 500
  end
end
