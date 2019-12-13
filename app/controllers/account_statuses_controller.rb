# Always check the latest value without using the cache.
class AccountStatusesController < ApplicationController

  before_action :require_login!
  before_action :reject_crawler
  before_action { valid_uid?(params[:uid]) }

  before_action { create_search_log }

  before_action do
    uid = searchee_uid
    status = AccountStatus.new

    begin
      request_context_client.twitter.user(uid)
    rescue => e
      status = AccountStatus.new(ex: e)
    end

    if status.unauthorized?
      render json: {authorized: false, uid: uid}
    elsif status.not_found? || status.suspended?
      # It's strange to reach here because you can search.

      searchee = TwitterUser.latest_by(uid: uid)
      searchee = TwitterDB::User.find_by(uid: uid) unless searchee

      if searchee
        if status.not_found?
          CreateNotFoundUserWorker.perform_async(searchee.screen_name)
        elsif status.suspended?
          CreateForbiddenUserWorker.perform_async(searchee.screen_name)
        end
      end

      render json: {authorized: true, uid: uid, suspended: status.suspended?, not_found: status.not_found?}
    else
      CreateTwitterDBUserWorker.perform_async([uid], user_id: current_user.id, force_update: true)
    end
  end

  before_action do
    next if current_user.uid == searchee_uid

    uid = searchee_uid
    status = AccountStatus.new

    begin
      request_context_client.twitter.user_timeline(uid, count: 1)
    rescue => e
      status = AccountStatus.new(ex: e)
    end

    if status.protected? || status.blocked?
      # It's strange to reach here because you can search.
      render json: {authorized: true, uid: uid, not_authorized: status.protected?, blocked: status.blocked?}
    end
  end


  before_action do
    uid = searchee_uid
    status = AccountStatus.new

    begin
      User.egotter.api_client.twitter.user_timeline(uid, count: 1)
    rescue => e
      status = AccountStatus.new(ex: e)
    end

    if status.protected? || status.blocked?
      render json: {authorized: true, uid: uid, egotter_not_authorized: status.protected?, egotter_blocked: status.blocked?}
    end
  end

  def show
    render json: {authorized: true, uid: searchee_uid}
  end

  private

  def searchee_uid
    params[:uid].to_i
  end
end
