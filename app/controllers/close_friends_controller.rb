class CloseFriendsController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper
  include PageCachesHelper
  include TweetTextHelper
  include CloseFriendsHelper

  before_action :reject_crawler, only: %i(create)
  before_action(only: %i(create show)) { valid_screen_name?(params[:screen_name]) }
  before_action(only: %i(create show)) { not_found_screen_name?(params[:screen_name]) }
  before_action(only: %i(create show)) { @tu = build_twitter_user(params[:screen_name]) }
  before_action(only: %i(create show)) { authorized_search?(@tu) }
  before_action(only: %i(show)) { existing_uid?(@tu.uid.to_i) }
  before_action only: %i(show) do
    @twitter_user = TwitterUser.latest(@tu.uid.to_i)
    remove_instance_variable(:@tu)
  end
  before_action only: %i(new create show) do
    if request.format.html?
      push_referer
      create_search_log(action: "#{controller_name}/#{action_name}")
    end
  end

  def new
    @title = t('one_sided_friends.new.plain_title')
  end

  def show
    @api_path = api_v1_close_friends_list_path
    @breadcrumb_name = :close_friend
    @canonical_url = close_friend_url(screen_name: @twitter_user.screen_name)
    @page_title = t('close_friends.show.title_with_name', user: @twitter_user.mention_name)

    uids = @twitter_user.close_friendships.limit(5).pluck(:friend_uid)
    users = TwitterDB::User.where(uid: uids).index_by(&:uid)
    users = uids.map { |uid| users[uid] }.compact
    @tweet_text = close_friends_text(users, @twitter_user)

    screen_names = users.map(&:mention_name)
    @meta_description = t('close_friends.show.thanks', users: "#{screen_names.map { |sn| "#{sn}#{t('dictionary.honorific')}" }.join(t('dictionary.delim'))}")
  end
end
