class FriendsController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper

  before_action(only: %i(show)) do
    if request.format.html?
      if valid_screen_name?(params[:screen_name])
        case params[:type]
          when 'friends' then redirect_to(friend_path(screen_name: params[:screen_name]), status: 301)
          when 'followers' then redirect_to(follower_path(screen_name: params[:screen_name]), status: 301)
          when 'statuses' then redirect_to(status_path(screen_name: params[:screen_name]), status: 301)
        end
      end
    else
      head :not_found
    end
  end

  before_action(only: %i(show)) { valid_screen_name?(params[:screen_name]) }
  before_action(only: %i(show)) { not_found_screen_name?(params[:screen_name]) }
  before_action(only: %i(show)) { @tu = build_twitter_user(params[:screen_name]) }
  before_action(only: %i(show)) { authorized_search?(@tu) }
  before_action(only: %i(show)) { existing_uid?(@tu.uid.to_i) }
  before_action(only: %i(show))  do
    @twitter_user = TwitterUser.latest(@tu.uid.to_i)
    remove_instance_variable(:@tu)
  end
  before_action do
    push_referer
    create_search_log
  end

  def new
  end

  def show
    @api_path = send("api_v1_#{controller_name}_list_path")
    @breadcrumb_name = controller_name.singularize.to_sym
    @canonical_url = send("#{controller_name.singularize}_url", screen_name: @twitter_user.screen_name)
    @page_title = t('.page_title', user: @twitter_user.mention_name)

    counts = {
      friends: @twitter_user.friendships.size,
      one_sided_friends: @twitter_user.one_sided_friendships.size,
      one_sided_friends_rate: (@twitter_user.one_sided_friends_rate * 100).round(1)
    }

    @meta_title = t('.meta_title', {user: @twitter_user.mention_name}.merge(counts))

    @page_description = t('.page_description', user: @twitter_user.mention_name)
    @meta_description = t('.meta_description', {user: @twitter_user.mention_name}.merge(counts))

    @tweet_text = t('.tweet_text', {user: @twitter_user.mention_name, url: @canonical_url}.merge(counts))

    @stat = UsageStat.find_by(uid: @twitter_user.uid)
  end
end
