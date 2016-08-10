class BackgroundSearchLogsController < ApplicationController
  include PageCachesHelper

  before_action :basic_auth, only: :index

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
    unless TwitterUser.new(uid: params[:id]).valid_uid?
      return render json: {reason: t('before_sign_in.that_page_doesnt_exist')}, status: 400
    end

    uid = params[:id].to_i
    user_id = current_user_id
    unless Util::SearchedUidList.new(redis).exists?(uid, user_id)
      return render json: {reason: t('before_sign_in.that_page_doesnt_exist')}, status: 400
    end

    case
      when BackgroundSearchLog.processing?(uid, user_id)
        render nothing: true, status: 202
      when BackgroundSearchLog.successfully_finished?(uid, user_id)
        created_at = TwitterUser.latest(uid, user_id).created_at.to_i
        render json: {created_at: created_at, hash: delete_cache_token(created_at)}, status: 200
      when BackgroundSearchLog.failed?(uid, user_id)
        render json: {
          reason: BackgroundSearchLog.fail_reason!(uid, user_id),
          message: BackgroundSearchLog.fail_message!(uid, user_id)
        }, status: 500
      else
        render json: {reason: BackgroundSearchLog::SomethingError::MESSAGE}, status: 500
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    render json: {reason: BackgroundSearchLog::SomethingError::MESSAGE}, status: 500
  end
end
