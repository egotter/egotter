class RelationshipsController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper
  include RelationshipsHelper

  before_action :reject_crawler, only: %i(create waiting)
  before_action(only: %i(create show)) { screen_names.all? { |sn| valid_screen_name?(sn) } }
  before_action(only: %i(create show)) { need_login }
  before_action(only: %i(create show)) { screen_names.any? { |sn| not_found_screen_name?(sn) } }
  before_action(only: %i(create show)) { @tu = screen_names.map { |sn| build_twitter_user(sn) } }
  before_action(only: %i(create show)) { @tu.all? { |tu| authorized_search?(tu) } }
  before_action(only: %i(show)) { @tu.all? { |tu| existing_uid?(tu.uid.to_s) } }
  before_action only: %i(show) do
    @twitter_users = @tu.map { |tu| TwitterUser.latest(tu.uid.to_i) }
    remove_instance_variable(:@tu)
  end

  before_action(only: %i(waiting check_log)) { uids.all? { |uid| valid_uid?(uid.to_i) } }
  before_action(only: %i(waiting check_log)) { uids.all? { |uid| searched_uid?(uid.to_i) } }

  before_action only: %i(new create waiting show) do
    if request.format.html?
      push_referer
      if action_name == 'show'
        create_search_log(action: "#{controller_name}/#{get_type}")
      else
        create_search_log(action: "#{controller_name}/#{action_name}")
      end
    end
  end

  VALID_TYPES = %w(conversations common_friends common_followers)

  def new
    @title = t('relationships.new.plain_title')
  end

  def show
    @type = get_type

    respond_to do |format|
      format.html { render }
      format.json do
        tweets_or_users = Kaminari.paginate_array(@twitter_users[0].send(@type, @twitter_users[1])).page(params[:page]).per(50)
        if tweets_or_users.empty?
          render json: {empty: true}, status: 200
        else
          render json: {html: render_to_string(locals: {type: @type, tweets_or_users: tweets_or_users, twitter_users: @twitter_users})}, status: 200
        end
      end
    end
  end

  def create
    @tu.each { |tu| save_twitter_user_to_cache(tu.uid.to_i, screen_name: tu.screen_name, user_info: tu.user_info) }

    if @tu.any? { |tu| !TwitterUser.exists?(uid: tu.uid.to_i) }
      add_create_relationship_worker_if_needed(@tu.map(&:uid), user_id: current_user_id, screen_names: @tu.map(&:screen_name))
      redirect_to waiting_relationship_path(src_uid: @tu[0].uid, dst_uid: @tu[1].uid, type: params[:type])
    else
      redirect_to relationship_path(src_screen_name: @tu[0].screen_name, dst_screen_name: @tu[1].screen_name, type: params[:type])
    end
  end

  def waiting
    twitter_users = uids.map { |uid| fetch_twitter_user_from_cache(uid.to_i) }
    if twitter_users.any?(&:nil?)
      return redirect_to relationships_top_path, alert: t('before_sign_in.that_page_doesnt_exist')
    end

    @result_path = relationship_path(src_screen_name: twitter_users[0].screen_name, dst_screen_name: twitter_users[1].screen_name, type: params[:type])
    @twitter_users = twitter_users
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

  def get_type
    VALID_TYPES.include?(params[:type]) ? params['type'] : VALID_TYPES[0]
  end
end
