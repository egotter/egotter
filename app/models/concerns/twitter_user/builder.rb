require 'active_support/concern'

module Concerns::TwitterUser::Builder
  extend ActiveSupport::Concern
  include Concerns::TwitterUser::AssociationBuilder

  class_methods do
    def build_by_user(user)
      TwitterUser.new(
        uid: user.id,
        screen_name: user.screen_name,
        user_info: TwitterUser.collect_user_info(user)
      )
    end

    def builder(uid)
      Builder.new(uid)
    end
  end

  class Builder
    attr_reader :uid, :error_message

    def initialize(uid)
      @uid = uid.to_i
      @error_message = nil
      @login_user = nil
      @client = nil
    end

    # These validation methods (fresh?, friendless? and diff.empty?) are not implemented in
    # Rails default validation callbacks due to too heavy.
    def build(validate: true)
      t_user = @client.user(uid)
      latest = TwitterUser.latest(uid)

      unless latest
        twitter_user = TwitterUser.build_by_user(t_user)
        relations = TwitterUserFetcher.new(twitter_user, client: @client, login_user: @login_user).fetch
        twitter_user.build_friends_and_followers(relations[:friend_ids], relations[:follower_ids])
        twitter_user.build_other_relations(relations)
        twitter_user.user_id = @login_user ? @login_user.id : -1
        return twitter_user
      end

      if validate && latest.fresh?
        @error_message = 'Recently updated'
        return nil
      end

      twitter_user = TwitterUser.build_by_user(t_user)
      relations = TwitterUserFetcher.new(twitter_user, client: @client, login_user: @login_user).fetch
      twitter_user.build_friends_and_followers(relations[:friend_ids], relations[:follower_ids])

      if validate
        if twitter_user.friendless?
          @error_message = 'Too many friends (already exists)'
          return nil
        end

        if latest.diff(twitter_user).empty?
          @error_message = 'Not changed (before building)'
          return nil
        end
      end

      twitter_user.build_other_relations(relations)
      twitter_user.user_id = @login_user ? @login_user.id : -1
      twitter_user
    end

    def login_user(login_user)
      @login_user = login_user
      self
    end

    def client(client)
      @client = client
      self
    end
  end
end
