# == Schema Information
#
# Table name: twitter_users
#
#  id             :integer          not null, primary key
#  uid            :string(191)      not null
#  screen_name    :string(191)      not null
#  friends_size   :integer          default(0), not null
#  followers_size :integer          default(0), not null
#  user_info      :text(65535)      not null
#  search_count   :integer          default(0), not null
#  update_count   :integer          default(0), not null
#  user_id        :integer          not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_twitter_users_on_created_at               (created_at)
#  index_twitter_users_on_screen_name              (screen_name)
#  index_twitter_users_on_screen_name_and_user_id  (screen_name,user_id)
#  index_twitter_users_on_uid                      (uid)
#  index_twitter_users_on_uid_and_user_id          (uid,user_id)
#

class TwitterUser < ActiveRecord::Base
  include Concerns::TwitterUser::Associations
  include Concerns::TwitterUser::Store
  include Concerns::TwitterUser::Validation
  include Concerns::TwitterUser::Inflections
  include Concerns::TwitterUser::Builder
  include Concerns::TwitterUser::Utils
  include Concerns::TwitterUser::Api
  include Concerns::TwitterUser::Dirty
  include Concerns::TwitterUser::Persistence

  include Concerns::TwitterUser::Debug

  def cache_key
    case
      when new_record? then super
      else "#{self.class.model_name.cache_key}/#{id}" # do not use timestamps
    end
  end

  def self.builder(uid)
    Builder.new(uid)
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
      login_user = @login_user || build_login_user
      client = @client || build_client

      t_user = client.user(uid)
      new_tu = TwitterUser.build_by_user(t_user)
      relations = TwitterUserFetcher.new(new_tu, client: client, login_user: login_user).fetch
      latest = nil

      if validate
        latest = TwitterUser.latest(uid)
        if latest&.fresh?
          @error_message = 'recently updated'
          return false
        end
      end

      new_tu.build_friends_and_followers(relations[:friend_ids], relations[:follower_ids])

      if validate
        latest = TwitterUser.latest(uid) unless latest
        if latest && new_tu.friendless?
          @error_message = 'already created and too many friends'
          return false
        end

        if latest&.diff(new_tu)&.empty?
          @error_message = 'not changed (before building)'
          return false
        end
      end

      new_tu.build_other_relations(relations)
      new_tu.user_id = login_user ? login_user.id : -1
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

    private

    def build_login_user
      @login_user || User.find_by(uid: uid)
    end

    def build_client
      if @login_user
        @login_user.authorized? ? @login_user.api_client : Bot.api_client
      else
        user = User.find_by(uid: uid, authorized: true)
        user ? user.api_client : Bot.api_client
      end
    end
  end
end
