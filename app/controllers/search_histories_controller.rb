# TODO Rename to Api::V1::SearchHistoriesController
class SearchHistoriesController < ApplicationController
  def new
    users = current_search_histories.map(&:twitter_db_user).compact
    render json: {users: to_hash(users)}
  end

  private

  def to_hash(users)
    via = current_via('search_histories')
    vc = view_context

    users.map do |user|
      user = TwitterUserDecorator.new(user)
      {
          screen_name: user.screen_name,
          profile_image_url: vc.bigger_icon_url(user),
          name_with_icon: user.name_with_icon,
          status_labels: user.status_labels,
          followed_label: vc.current_user_follower_uids.include?(user.uid) ? user.single_followed_label : nil,
          description: vc.linkify(user.description),
          friends_count: user.delimited_friends_count,
          followers_count: user.delimited_followers_count,
          timeline_url: timeline_path(user, via: via),
          friend_url: friend_path(user, via: via),
          follower_url: follower_path(user, via: via),
      }
    end
  end
end
