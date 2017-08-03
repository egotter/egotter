class CloseFriendsController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper
  include TweetTextHelper
  include CloseFriendsHelper

  before_action { valid_screen_name?(params[:screen_name]) }
  before_action { not_found_screen_name?(params[:screen_name]) }
  before_action { @tu = build_twitter_user(params[:screen_name]) }
  before_action { authorized_search?(@tu) }
  before_action { existing_uid?(@tu.uid.to_i) }
  before_action  do
    @twitter_user = TwitterUser.latest(@tu.uid.to_i)
    remove_instance_variable(:@tu)
  end
  before_action do
    push_referer
    create_search_log
  end

  def show
    @api_path = api_v1_close_friends_list_path
    @breadcrumb_name = :close_friend
    @canonical_url = close_friend_url(screen_name: @twitter_user.screen_name)
    @page_title = t('.page_title', user: @twitter_user.mention_name)

    uids = @twitter_user.close_friendships.limit(5).pluck(:friend_uid)
    users = TwitterDB::User.where(uid: uids).index_by(&:uid)
    users = uids.map { |uid| users[uid] }.compact
    @tweet_text = close_friends_text(users, @twitter_user)

    names = users.map(&:mention_name).map { |name| "#{name}#{t('dictionary.honorific')}" }.join(t('dictionary.delim'))
    @meta_description = t('.meta_description', users: names)

    @stat = UsageStat.find_by(uid: @twitter_user.uid)
  end
end
