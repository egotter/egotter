class CloseFriendsController < ::Base
  include TweetTextHelper
  include CloseFriendsHelper

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
