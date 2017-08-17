class CloseFriendsController < ApplicationController
  include Validation
  include Concerns::Logging
  include SearchesHelper
  include TweetTextHelper
  include CloseFriendsHelper

  before_action { valid_screen_name? && !not_found_screen_name? && !forbidden_screen_name? }
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
    @api_path = send("api_v1_#{controller_name}_list_path")
    @breadcrumb_name = controller_name.singularize.to_sym
    @canonical_url = send("#{controller_name.singularize}_url", screen_name: @twitter_user.screen_name)
    @page_title = t('.page_title', user: @twitter_user.mention_name)

    uids = @twitter_user.close_friendships.limit(5).pluck(:friend_uid)
    users = TwitterDB::User.where(uid: uids).index_by(&:uid)
    users = uids.map { |uid| users[uid] }.compact
    @tweet_text = close_friends_text(users, @twitter_user)

    @meta_description = t('.meta_description', users: honorific_names(users.map(&:mention_name)))

    @stat = UsageStat.find_by(uid: @twitter_user.uid)
  end
end
