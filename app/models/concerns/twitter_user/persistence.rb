require 'active_support/concern'
module Concerns::TwitterUser::Persistence
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    # With transactional_fixtures = true, after_commit callbacks is not fired.
    if Rails.env.test?
      after_create :put_relations_back
    else
      # Relations are created on `after_commit` in order to avoid long transaction.
      after_commit :put_relations_back, on: :create
    end
  end

  private

  def put_relations_back
    ActiveRecord::Base.benchmark('[benchmark] import Friendship and Followership') { logger.silence { ActiveRecord::Base.transaction {
      Friendship.import_from!(self.id, friendships.map(&:friend_uid))
      Followership.import_from!(self.id, followerships.map(&:follower_uid))
    }}}

    ActiveRecord::Base.benchmark('[benchmark] import Status') { logger.silence { ActiveRecord::Base.transaction {
      statuses.each { |r| r.from_id = id }.each_slice(1000) { |ary| Status.import(ary, validate: false) }
    }}}

    ActiveRecord::Base.benchmark('[benchmark] import Mention') { logger.silence { ActiveRecord::Base.transaction {
      mentions.each { |r| r.from_id = id }.each_slice(1000) { |ary| Mention.import(ary, validate: false) }
    }}}

    ActiveRecord::Base.benchmark('[benchmark] import SearchResult') { logger.silence { ActiveRecord::Base.transaction {
      search_results.each { |r| r.from_id = id }.each_slice(1000) { |ary| SearchResult.import(ary, validate: false) }
    }}}

    ActiveRecord::Base.benchmark('[benchmark] import Favorite') { logger.silence { ActiveRecord::Base.transaction {
      favorites.each { |r| r.from_id = id }.each_slice(1000) { |ary| Favorite.import(ary, validate: false) }
    }}}

    ActiveRecord::Base.benchmark('[benchmark] import Unfriendship') { logger.silence {
      Unfriendship.import_from!(uid, calc_removing_uids)
    }}

    ActiveRecord::Base.benchmark('[benchmark] import Unfollowership') { logger.silence {
      Unfollowership.import_from!(uid, calc_removed_uids)
    }}

    ActiveRecord::Base.benchmark('[benchmark] import OneSidedFriendship') { logger.silence {
      OneSidedFriendship.import_from!(uid, calc_one_sided_friend_uids)
    }}

    ActiveRecord::Base.benchmark('[benchmark] import OneSidedFollowership') { logger.silence {
      OneSidedFollowership.import_from!(uid, calc_one_sided_follower_uids)
    }}

    ActiveRecord::Base.benchmark('[benchmark] import MutualFriendship') { logger.silence {
      MutualFriendship.import_from!(uid, calc_mutual_friend_uids)
    }}

    reload
  rescue => e
    message = e.message.truncate(150)
    logger.warn "#{self.class}##{__method__}: #{e.class} #{message} #{self.inspect}"
    logger.info e.backtrace.join("\n")
    destroy
  end
end
