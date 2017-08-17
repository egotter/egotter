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

    def build(validate: true)
      t_user = @client.user(uid)
      new_tu = TwitterUser.build_by_user(t_user)
      relations = TwitterUserFetcher.new(new_tu, client: @client, login_user: @login_user).fetch
      latest = nil

      if validate
        latest = TwitterUser.latest(uid)
        if latest&.fresh?
          @error_message = 'recently updated'
          return nil
        end
      end

      new_tu.build_friends_and_followers(relations[:friend_ids], relations[:follower_ids])

      if validate
        latest = TwitterUser.latest(uid) unless latest
        if latest && new_tu.friendless?
          @error_message = 'already created and too many friends'
          return nil
        end

        if latest&.diff(new_tu)&.empty?
          @error_message = 'not changed (before building)'
          return nil
        end
      end

      new_tu.build_other_relations(relations)
      new_tu.user_id = @login_user ? @login_user.id : -1
      new_tu
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
