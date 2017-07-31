class TimelinesController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper
  include PageCachesHelper
  include WorkersHelper

  before_action(only: %i(show)) { valid_screen_name?(params[:screen_name]) }
  before_action(only: %i(show)) { not_found_screen_name?(params[:screen_name]) }
  before_action(only: %i(show)) { @tu = build_twitter_user(params[:screen_name]) }
  before_action(only: %i(show)) { authorized_search?(@tu) }
  before_action(only: %i(show)) { existing_uid?(@tu.uid.to_i) }
  before_action only: %i(show) do
    @twitter_user = TwitterUser.latest(@tu.uid.to_i)
    remove_instance_variable(:@tu)
  end

  before_action only: (%i(new create waiting show force_update) + Search::MENU) do
    push_referer
    create_search_log
  end

  def show
    if @twitter_user.forbidden_account?
      flash.now[:alert] = forbidden_message(@twitter_user.screen_name)
    end
  end

  def check_for_updates
    uid = params[:uid].to_i
    if valid_uid?(uid) && existing_uid?(uid) && params[:created_at].match(/\A\d+\z/)
      @twitter_user = TwitterUser.latest(uid)
      if authorized_search?(@twitter_user) && @twitter_user.created_at > Time.zone.at(params[:created_at].to_i)
        return render json: {found: true}, status: 200
      end
    end

    render json: {found: false}, status: 200
  end
end
