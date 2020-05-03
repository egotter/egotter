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

    status = AccountStatus.new
    begin
      # Raise an exception if the sign-in user is blocked from the searchee user
      request_context_client.twitter.user_timeline(searchee_uid, count: 1)
    rescue => e
      status = AccountStatus.new(ex: e)
    end

    if status.protected? || status.blocked?
      # It's strange to reach here because you can search.
      res = {authorized: true, uid: searchee_uid, not_permitted: status.protected?, blocked: status.blocked?}
      logger.debug { "#{controller_name}##{action_name} res=#{res} exception=#{status.exception}" }
      render json: res
    end
  end


  before_action do
    status = AccountStatus.new
    begin
      # Raise an exception if the egotter is blocked from the sign-in user
      User.egotter.api_client.twitter.user_timeline(current_user.uid, count: 1)
    rescue => e
      status = AccountStatus.new(ex: e)
    end

    if status.protected? || status.blocked?
      res = {authorized: true, uid: searchee_uid, egotter_not_permitted: status.protected?, egotter_blocked: status.blocked?}
      logger.debug { "#{controller_name}##{action_name} res=#{res} exception=#{status.exception}" }
      render json: res
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
