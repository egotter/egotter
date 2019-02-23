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
    mentions.each       { |r| r.from_id = id }
    search_results.each { |r| r.from_id = id }

    options = {validate: false}

    begin
      silent_transaction { TwitterDB::Status.import_by!(twitter_user: self) }
    rescue => e
      logger.warn "#{__method__} statuses: Continue to saving #{e.class} #{e.message.truncate(100)} #{self.inspect}"
    end
    silent_transaction { mentions.each_slice(1000)       { |ary| Mention.import(ary, options) } }
    silent_transaction { search_results.each_slice(1000) { |ary| SearchResult.import(ary, options) } }
    begin
      silent_transaction { TwitterDB::Favorite.import_by!(twitter_user: self) }
    rescue => e
      logger.warn "#{__method__} favorites: Continue to saving #{e.class} #{e.message.truncate(100)} #{self.inspect}"
    end

    # Set friends_size and followers_size in AssociationBuilder#build_friends_and_followers

    if Rails.env.test?
      friendships.each { |f| f.from_id = id }.each(&:save!)
      followerships.each { |f| f.from_id = id }.each(&:save!)
    end
  rescue => e
    # ActiveRecord::RecordNotFound Couldn't find TwitterUser with 'id'=00000
    # ActiveRecord::StatementInvalid Mysql2::Error: Deadlock found when trying to get lock;
    logger.warn "#{__method__}: #{e.class} #{e.message.truncate(120)} #{self.inspect}"
    logger.info e.backtrace.join("\n")
    destroy
  end
end
