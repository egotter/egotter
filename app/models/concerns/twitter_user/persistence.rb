require 'active_support/concern'
module Concerns::TwitterUser::Persistence
  extend ActiveSupport::Concern

  class_methods do
    def import_relations!(id, attr, values)
      klass = attr.to_s.classify.constantize
      benchmark_and_silence(attr) do
        values.each { |v| v.from_id = id }
        ActiveRecord::Base.transaction do
          values.each_slice(1000).each { |ary| klass.import(ary, validate: false) }
        end
      end
    end

    def benchmark_and_silence(attr)
      ActiveRecord::Base.benchmark("#{self.class}#import_relations! #{attr}") do
        logger.silence { yield }
      end
    end
  end

  included do
    before_create :push_relations_aside

    # With transactional_fixtures = true, after_commit callbacks is not fired.
    if Rails.env.test?
      after_create :call_all_callbacks
    else
      after_commit :call_all_callbacks, on: :create
    end
  end

  private

  def call_all_callbacks
    put_relations_back
    import_unfriends
    import_unfollowers
    import_twitter_db_users
    import_relationships
  end

  def push_relations_aside
    # Fetch before calling save, or `SELECT * FROM relation_name WHERE from_id = xxx` is executed
    # even if `auto_save: false` is specified.
    @shaded = %i(friends followers statuses mentions search_results favorites).map { |attr| [attr, send(attr).to_a.dup] }.to_h
    @shaded.keys.each { |attr| send("#{attr}=", []) }
  end

  def put_relations_back
    # Relations are created on `after_commit` in order to avoid long transaction.
    @shaded.each { |attr, values| self.class.import_relations!(self.id, attr, values) }
    remove_instance_variable(:@shaded)
    reload
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{self.inspect}"
    destroy
  end

  def import_unfriends
    self.class.benchmark_and_silence(:unfriends) do
      Unfriendship.import_from!(self.uid, self.calc_removing.map(&:uid))
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{self.inspect}"
    false
  end

  def import_unfollowers
    self.class.benchmark_and_silence(:unfollowers) do
      Unfollowership.import_from!(self.uid, self.calc_removed.map(&:uid))
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{self.inspect}"
    false
  end

  def import_twitter_db_users
    self.class.benchmark_and_silence(:twitter_db_users) do
      TwitterDB::User.import_from!(friends)
      TwitterDB::User.import_from!(followers)
      TwitterDB::User.import_from!([self])
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{self.inspect}"
    false
  end

  def import_relationships
    self.class.benchmark_and_silence(:twitter_db_users) do
      user = TwitterDB::User.find_by(uid: self.uid)

      ActiveRecord::Base.transaction do
        TwitterDB::Friendship.import_from!(self.uid, friend_uids)
        TwitterDB::Followership.import_from!(self.uid, follower_uids)

        Friendship.import_from!(self.id, friend_uids)
        Followership.import_from!(self.id, follower_uids)

        self.update_columns(friends_size: friend_uids.size, followers_size: follower_uids.size)
        user.update_columns(friends_size: friend_uids.size, followers_size: follower_uids.size)
      end
    end
  rescue => e
    logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{self.inspect}"
    false
  end
end
