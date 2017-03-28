require 'active_support/concern'
module Concerns::TwitterUser::Persistence
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    # Relations are created on `after_commit` in order to avoid long transaction.
    # With transactional_fixtures = true, after_commit callbacks is not fired.
    Rails.env.test? ? after_create { put_relations_back } : after_commit(on: :create) { put_relations_back }
  end

  private

  def put_relations_back
    statuses.each { |r| r.from_id = id }
    mentions.each { |r| r.from_id = id }
    search_results.each { |r| r.from_id = id }
    favorites.each { |r| r.from_id = id }

    options = {validate: false}

    _transaction('import Status') { statuses.each_slice(1000) { |ary| Status.import(ary, options) } }
    _transaction('import Mention') { mentions.each_slice(1000) { |ary| Mention.import(ary, options) } }
    _transaction('import SearchResult') { search_results.each_slice(1000) { |ary| SearchResult.import(ary, options) } }
    _transaction('import Favorite') { favorites.each_slice(1000) { |ary| Favorite.import(ary, options) } }

    if Rails.env.test?
      friendships.each { |f| f.from_id = id }.each(&:save!)
      followerships.each { |f| f.from_id = id }.each(&:save!)
    else
      reload
      ImportTwitterUserRelationsWorker.perform_async(user_id, uid.to_i, 'queued_at' => Time.zone.now, 'enqueued_at' => Time.zone.now)
    end

  rescue => e
    # ActiveRecord::RecordNotFound Couldn't find TwitterUser with 'id'=00000
    # ActiveRecord::StatementInvalid Mysql2::Error: Deadlock found when trying to get lock;
    message = e.message.truncate(150)
    logger.warn "#{self.class}##{__method__}: #{e.class} #{message} #{id} #{uid} #{screen_name}"
    logger.info e.backtrace.join("\n")
    destroy
  end
end
