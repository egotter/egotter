require 'active_support/concern'
module Concerns::TwitterUser::Persistence
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    # With transactional_fixtures = true, after_commit callbacks is not fired.
    if Rails.env.test?
      after_create do
        logger.silence { put_relations_back }
      end
    else
      # Relations are created on `after_commit` in order to avoid long transaction.
      after_commit on: :create do
        logger.silence { put_relations_back }
      end
    end
  end

  private

  def put_relations_back
    ActiveRecord::Base.benchmark('[benchmark] import Status') { ActiveRecord::Base.transaction {
      statuses.each { |r| r.from_id = id }.each_slice(1000) { |ary| Status.import(ary, validate: false) }
    }}

    ActiveRecord::Base.benchmark('[benchmark] import Mention') { ActiveRecord::Base.transaction {
      mentions.each { |r| r.from_id = id }.each_slice(1000) { |ary| Mention.import(ary, validate: false) }
    }}

    ActiveRecord::Base.benchmark('[benchmark] import SearchResult') { ActiveRecord::Base.transaction {
      search_results.each { |r| r.from_id = id }.each_slice(1000) { |ary| SearchResult.import(ary, validate: false) }
    }}

    ActiveRecord::Base.benchmark('[benchmark] import Favorite') { ActiveRecord::Base.transaction {
      favorites.each { |r| r.from_id = id }.each_slice(1000) { |ary| Favorite.import(ary, validate: false) }
    }}

    reload
  rescue => e
    # ActiveRecord::StatementInvalid Mysql2::Error: Deadlock found when trying to get lock;
    # ActiveRecord::RecordNotFound Couldn't find TwitterUser with 'id'=00000
    message = e.message.truncate(150)
    logger.warn "#{self.class}##{__method__}: #{e.class} #{message} #{self.inspect}"
    logger.info e.backtrace.join("\n")
    destroy
  end
end
