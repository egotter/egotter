require 'active_support/concern'

module Concerns::TwitterUser::Associations
  extend ActiveSupport::Concern

  class_methods do
    def twitter_db_name
      Rails.application.config.database_configuration["twitter_#{Rails.env}"]['database']
    end
  end

  included do
    with_options foreign_key: :from_id, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :statuses
      obj.has_many :mentions
      obj.has_many :search_results
      obj.has_many :favorites
    end

    with_options primary_key: :id, foreign_key: :from_id, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friendships, -> { order(sequence: :asc) }
      obj.has_many :followerships, -> { order(sequence: :asc) }
    end

    with_options primary_key: :uid, foreign_key: :from_uid, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :unfriendships, -> { order(sequence: :asc) }
      obj.has_many :unfollowerships, -> { order(sequence: :asc) }
    end
  end

  def friends
    proxy = CollectionProxy.new(self)
    db = TwitterUser.twitter_db_name

    proxy.sql = <<-SQL.squish
      SELECT #{db}.users.*
      FROM #{db}.users INNER JOIN friendships ON #{db}.users.uid = friendships.friend_uid
      WHERE friendships.from_id = #{proxy.owner.id}
      ORDER BY friendships.sequence ASC
    SQL

    def proxy.where(uid: nil)
      db = TwitterUser.twitter_db_name
      self.uid = uid
      self.sql = <<-SQL.squish
        SELECT #{db}.users.*
        FROM #{db}.users INNER JOIN friendships ON #{db}.users.uid = friendships.friend_uid
        WHERE friendships.from_id = #{owner.id} #{"AND friendships.friend_uid IN (#{uid.join(', ')})" if uid}
        ORDER BY friendships.sequence ASC
      SQL
      self
    end

    def proxy.size
      db = TwitterUser.twitter_db_name
      sql = <<-SQL.squish
        SELECT count(*) cnt
        FROM #{db}.users INNER JOIN friendships ON #{db}.users.uid = friendships.friend_uid
        WHERE friendships.from_id = #{owner.id} #{"AND friendships.friend_uid IN (#{uid.join(', ')})" if uid}
      SQL
      ActiveRecord::Base.connection.select_all(sql).to_a.first['cnt']
    end

    proxy
  end

  def followers
    proxy = CollectionProxy.new(self)
    db = TwitterUser.twitter_db_name

    proxy.sql = <<-SQL.squish
      SELECT #{db}.users.*
      FROM #{db}.users INNER JOIN followerships ON #{db}.users.uid = followerships.follower_uid
      WHERE followerships.from_id = #{proxy.owner.id}
      ORDER BY followerships.sequence ASC
    SQL

    def proxy.where(uid: nil)
      db = TwitterUser.twitter_db_name
      self.uid = uid
      self.sql = <<-SQL.squish
        SELECT #{db}.users.*
        FROM #{db}.users INNER JOIN followerships ON #{db}.users.uid = followerships.follower_uid
        WHERE followerships.from_id = #{owner.id} #{"AND followerships.follower_uid IN (#{uid.join(', ')})" if uid}
        ORDER BY followerships.sequence ASC
      SQL
      self
    end

    def proxy.size
      db = TwitterUser.twitter_db_name
      sql = <<-SQL.squish
        SELECT count(*) cnt
        FROM #{db}.users INNER JOIN followerships ON #{db}.users.uid = followerships.follower_uid
        WHERE followerships.from_id = #{owner.id} #{"AND followerships.follower_uid IN (#{uid.join(', ')})" if uid}
      SQL
      ActiveRecord::Base.connection.select_all(sql).to_a.first['cnt']
    end

    proxy
  end

  def unfriends
    db = self.class.twitter_db_name
    sql = <<-SQL.squish
        SELECT #{db}.users.*
        FROM #{db}.users INNER JOIN unfriendships ON #{db}.users.uid = unfriendships.friend_uid
        WHERE unfriendships.from_uid = #{self.id}
        ORDER BY unfriendships.sequence ASC
    SQL
    ActiveRecord::Base.connection.select_all(sql).to_a.map { |u| TwitterDB::User.new(u) }
  end

  def unfollowers
    db = self.class.twitter_db_name
    sql = <<-SQL.squish
        SELECT #{db}.users.*
        FROM #{db}.users INNER JOIN unfollowerships ON #{db}.users.uid = unfollowerships.follower_uid
        WHERE unfollowerships.from_uid = #{self.id}
        ORDER BY unfollowerships.sequence ASC
    SQL
    ActiveRecord::Base.connection.select_all(sql).to_a.map { |u| TwitterDB::User.new(u) }
  end
end
