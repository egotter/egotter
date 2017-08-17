class SearchesController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper
  include WorkersHelper

  before_action :reject_crawler, only: %i(create waiting)
  before_action(only: Search::MENU + %i(create show)) { valid_screen_name? && !not_found_screen_name? && !forbidden_screen_name? }
  before_action(only: Search::MENU + %i(create show)) { @tu = build_twitter_user(params[:screen_name]) }
  before_action(only: Search::MENU + %i(create show)) { authorized_search?(@tu) }
  before_action(only: Search::MENU + %i(show)) { existing_uid?(@tu.uid.to_i) }
  before_action only: Search::MENU + %i(show) do
    @twitter_user = TwitterUser.latest(@tu.uid.to_i)
    remove_instance_variable(:@tu)
  end
  before_action(only: %i(waiting)) { valid_uid?(params[:uid].to_i) }
  before_action(only: %i(waiting)) { searched_uid?(params[:uid].to_i) }

  before_action only: (%i(new create waiting show) + Search::MENU) do
    push_referer

    if session[:sign_in_from].present?
      create_search_log(referer: session.delete(:sign_in_from))
    elsif session[:sign_out_from].present?
      create_search_log(referer: session.delete(:sign_out_from))
    else
      create_search_log
    end
  end

  def show
    redirect_to timeline_path(screen_name: @twitter_user.screen_name), status: 301
  end

  def new
  end

  def create
    uid, screen_name = @tu.uid.to_i, @tu.screen_name
    redirect_path = sanitized_redirect_path(params[:redirect_path].presence || search_path(screen_name: screen_name))
    if TwitterUser.exists?(uid: uid)
      redirect_to redirect_path
    else
      save_twitter_user_to_cache(uid, screen_name: screen_name, user_info: @tu.user_info)
      add_create_twitter_user_worker_if_needed(uid, user_id: current_user_id, screen_name: screen_name)
      redirect_to waiting_search_path(uid: uid, redirect_path: redirect_path)
    end

    enqueue_update_search_histories_worker_if_needed(uid)
  end

  def waiting
    uid = params[:uid].to_i
    tu = fetch_twitter_user_from_cache(uid)
    return redirect_to root_path, alert: t('before_sign_in.that_page_doesnt_exist') if tu.nil?

    @redirect_path = sanitized_redirect_path(params[:redirect_path].presence || search_path(screen_name: tu.screen_name))
    @twitter_user = tu
  end

  %i(favoriting).each do |menu|
    define_method(menu) do
      @menu = menu
      @title = title_for(menu, @twitter_user.screen_name)
      @description = "#{@title} - #{@twitter_user.description}"
      render :common
    end
  end
end
