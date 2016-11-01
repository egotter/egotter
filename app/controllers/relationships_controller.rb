class RelationshipsController < ApplicationController
  include Validation
  include Logging
  include SearchesHelper
  include RelationshipsHelper

  before_action :reject_crawler, only: %i(create)
  before_action(only: %i(create conversations common_friends common_followers)) { screen_names.all? { |sn| valid_screen_name?(sn) } }
  before_action(only: %i(create conversations common_friends common_followers)) { @tu = screen_names.map { |sn| build_twitter_user(sn) } }
  before_action(only: %i(create conversations common_friends common_followers)) { @tu.all? { |tu| authorized_search?(tu) } }
  before_action(only: %i(conversations common_friends common_followers)) { @tu.all? { |tu| existing_uid?(tu.uid.to_s) } }
  before_action only: %i(conversations common_friends common_followers) do
    @searched_tw_users = @tu.map { |tu| TwitterUser.latest(tu.uid.to_i) }
    remove_instance_variable(:@tu)
  end

  before_action(only: %i(waiting)) { uids.all? { |uid| valid_uid?(uid.to_i) } }
  before_action(only: %i(check_log)) { uids.all? { |uid| valid_uid?(uid.to_i) } }
  # before_action(only: %i(check_log)) { uids.all? { |uid| searched_uid?(uid.to_i) } }

  before_action only: %i(conversations common_friends common_followers) do
    push_referer
    create_search_log
  end

  def conversations
    statuses =
      @searched_tw_users[0].statuses.select { |s| s.text.starts_with?(@searched_tw_users[1].mention_name) } +
      @searched_tw_users[1].statuses.select { |s| s.text.starts_with?(@searched_tw_users[0].mention_name) }
    @statuses = Kaminari.paginate_array(statuses.sort_by { |s| -s.tweeted_at.to_i }.take(600)).page(params[:page]).per(100)
    @title = t('.title', user1: @searched_tw_users[0].mention_name, user2: @searched_tw_users[1].mention_name)
  end

  def common_friends
    # TODO implement
    @title = t('.title', user1: @searched_tw_users[0].mention_name, user2: @searched_tw_users[1].mention_name)
  end

  def common_followers
    @user_items = TwitterUsersDecorator.new(@searched_tw_users[0].common_followers(@searched_tw_users[1])).items
    @title = t('.title', user1: @searched_tw_users[0].mention_name, user2: @searched_tw_users[1].mention_name)
  end

  def create
    need_worker = false
    @tu.each do |tu|
      save_twitter_user_to_cache(tu.uid.to_i, screen_name: tu.screen_name, user_info: tu.user_info)
      need_worker = !TwitterUser.exists?(uid: tu.uid.to_i) unless need_worker
    end

    if need_worker
      add_create_relationship_worker_if_needed(@tu.map(&:uid), user_id: current_user_id, screen_names: @tu.map(&:screen_name))
      redirect_to waiting_relationship_path(src_uid: @tu[0].uid, dst_uid: @tu[1].uid, to: params[:to])
    else
      redirect_to result_page_path(@tu, to: params[:to])
    end
  end

  def waiting
    tu = uids.map { |uid| fetch_twitter_user_from_cache(uid.to_i) }
    if tu.any? { |t| t.nil? }
      return redirect_to root_path, alert: t('before_sign_in.that_page_doesnt_exist')
    end

    @result_path = result_page_path(tu, to: params[:to])
    @searched_tw_users = tu
  end

  def check_log
    log = CreateRelationshipLog.order(created_at: :desc).find_by(uid: uids.join(', '), user_id: current_user_id)

    case
      when log.nil? || log.processing?
        render nothing: true, status: 202
      when log.finished?
        render json: {message: log.message}, status: 200
      when log.failed?
        render json: {reason: log.reason, message: log.message}, status: 500
      else
        render json: {reason: BackgroundSearchLog::SomethingError::MESSAGE}, status: 500
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message}"
    render json: {reason: BackgroundSearchLog::SomethingError::MESSAGE}, status: 500
  end

  private

  def uids
    [params[:src_uid], params[:dst_uid]].map(&:to_i)
  end

  def screen_names
    [params[:src_screen_name], params[:dst_screen_name]]
  end

  def result_page_path(tw_users, to:)
    values = {src_screen_name: tw_users[0].screen_name, dst_screen_name: tw_users[1].screen_name}
    case to
      when 'conversations'    then conversation_path(values)
      when 'common_friends'   then common_friend_path(values)
      when 'common_followers' then common_follower_path(values)
      else raise "#{self.class}##{__method__}: #{to} is not permitted."
    end
  end
end
