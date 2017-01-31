require 'active_support/concern'

module Concerns::TwitterUser::AssociationBuilder
  extend ActiveSupport::Concern
  include Concerns::TwitterUser::Validation

  class_methods do
  end

  included do
  end

  def build_relations(client, login_user, context)
    relations = fetch_relations(client, login_user, context)

    users = []

    users =
      relations[:friends].map do |user|
        TwitterDB::User.new(uid: user.id, screen_name: user.screen_name, user_info: user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, friends_size: -1, followers_size: -1)
      end if relations[:friends]&.any?

    users +=
      relations[:followers].map do |user|
        TwitterDB::User.new(uid: user.id, screen_name: user.screen_name, user_info: user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json, friends_size: -1, followers_size: -1)
      end if relations[:followers]&.any?

    users << TwitterDB::User.new(uid: uid, screen_name: screen_name, user_info: user_info, friends_size: -1, followers_size: -1)

    ActiveRecord::Base.benchmark('import TwitterDB') { logger.silence { ActiveRecord::Base.transaction {
      users.uniq { |u| u.uid }.each_slice(1000) do |array|
        TwitterDB::User.import(array, on_duplicate_key_update: %i(uid screen_name user_info), validate: false)
      end

      TwitterDB::Friendship.import_from!(uid.to_i, relations[:friends].map(&:id)) if relations[:friends]&.any?
      TwitterDB::Followership.import_from!(uid.to_i, relations[:followers].map(&:id)) if relations[:followers]&.any?

      TwitterDB::User.find_by(uid: uid).tap { |user| user.update_columns(friends_size: user.friendships.size, followers_size: user.followerships.size) }
    }}}

    relations[:friends].each { |friend| friendships.build(friend_uid: friend.id) } if relations[:friends]&.any?
    relations[:followers].each { |follower| followerships.build(follower_uid: follower.id) } if relations[:followers]&.any?

    self.friends_size = friendships.size
    self.followers_size = followerships.size

    relations[:user_timeline].each do |status|
      statuses.build(uid: status.user.id, screen_name: status.user.screen_name, status_info: status.slice(*Status::STATUS_SAVE_KEYS).to_json)
    end if relations[:user_timeline]&.any?

    relations[:mentions_timeline].each do |mention|
      mentions.build(uid: mention.user.id, screen_name: mention.user.screen_name, status_info: mention.slice(*Status::STATUS_SAVE_KEYS).to_json)
    end if relations[:mentions_timeline]&.any?

    relations[:search].each do |search_result|
      search_results.build(uid: search_result.user.id, screen_name: search_result.user.screen_name, status_info: search_result.slice(*Status::STATUS_SAVE_KEYS).to_json)
    end if relations[:search]&.any?

    search_results.each { |search_result| search_result.query = mention_name }

    relations[:favorites].each do |favorite|
      favorites.build(uid: favorite.user.id, screen_name: favorite.user.screen_name, status_info: favorite.slice(*Status::STATUS_SAVE_KEYS).to_json)
    end if relations[:favorites]&.any?

    true
  end

  private

  # Not using uniq for mentions, search_results and favorites intentionally
  def fetch_relations(client, login_user, context)
    fetch_results = client._fetch_parallelly(fetch_signatures(login_user, context))
    client.replying(uid.to_i) # only create a cache

    fetch_signatures(login_user, context).each_with_object({}).with_index do |(item, memo), i|
      memo[item[:method]] = fetch_results[i]
    end
  end

  def fetch_signatures(login_user, context)
    reject_names = reject_relation_names(login_user, context)
    [
      {method: :friends,           args: [uid.to_i]},
      {method: :followers,         args: [uid.to_i]},
      {method: :user_timeline,     args: [uid.to_i, {include_rts: false}]},     # replying
      {method: :search,            args: [mention_name]}, # replied
      {method: :home_timeline,     args: [uid.to_i]},     # TODO cache?
      {method: :mentions_timeline, args: [uid.to_i]},     # replied
      {method: :favorites,         args: [uid.to_i]}      # favoriting
    ].delete_if { |item| reject_names.include?(item[:method]) }
  end

  def reject_relation_names(login_user, context)
    case [!!(login_user && login_user.uid.to_i == uid.to_i), too_many_friends?(login_user: login_user, context: context)]
      when [true, true]   then %i(friends followers)
      when [true, false]  then []
      when [false, true]  then %i(friends followers home_timeline mentions_timeline)
      when [false, false] then %i(home_timeline mentions_timeline)
    end
  end
end
