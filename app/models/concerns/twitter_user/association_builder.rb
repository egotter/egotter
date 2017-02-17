require 'active_support/concern'

module Concerns::TwitterUser::AssociationBuilder
  extend ActiveSupport::Concern
  include Concerns::TwitterUser::Validation

  class_methods do
  end

  included do
  end

  def build_friends_and_followers(relations)
    ActiveRecord::Base.benchmark('benchmark AssociationBuilder#build friend_ids and follower_ids') do
      relations[:friend_ids].each.with_index { |friend_id, i| friendships.build(friend_uid: friend_id, sequence: i) } if relations[:friend_ids]&.any?
      relations[:follower_ids].each.with_index { |follower_id, i| followerships.build(follower_uid: follower_id, sequence: i) } if relations[:follower_ids]&.any?
    end

    self.friends_size = friendships.size
    self.followers_size = followerships.size
  end

  def build_other_relations(relations)
    # This process takes a few seconds.
    ActiveRecord::Base.benchmark('benchmark AssociationBuilder#build statuses') do
      relations[:user_timeline].each do |status|
        statuses.build(uid: status.user.id, screen_name: status.user.screen_name, status_info: status.slice(*Status::STATUS_SAVE_KEYS).to_json)
      end if relations[:user_timeline]&.any?
    end

    ActiveRecord::Base.benchmark('benchmark AssociationBuilder#build mentions_timeline') do
      relations[:mentions_timeline].each do |mention|
        mentions.build(uid: mention.user.id, screen_name: mention.user.screen_name, status_info: mention.slice(*Status::STATUS_SAVE_KEYS).to_json)
      end if relations[:mentions_timeline]&.any?
    end

    ActiveRecord::Base.benchmark('benchmark AssociationBuilder#build search_results') do
      relations[:search].each do |search_result|
        search_results.build(uid: search_result.user.id, screen_name: search_result.user.screen_name, status_info: search_result.slice(*Status::STATUS_SAVE_KEYS).to_json)
      end if relations[:search]&.any?
    end

    ActiveRecord::Base.benchmark('benchmark AssociationBuilder set search_query') do
      search_query = mention_name
      search_results.each { |search_result| search_result.query = search_query }
    end

    # This process takes a few seconds.
    ActiveRecord::Base.benchmark('benchmark AssociationBuilder#build favorites') do
      relations[:favorites].each do |favorite|
        favorites.build(uid: favorite.user.id, screen_name: favorite.user.screen_name, status_info: favorite.slice(*Status::STATUS_SAVE_KEYS).to_json)
      end if relations[:favorites]&.any?
    end
  end
end
