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
    [TwitterDB::Status, TwitterDB::Mention, TwitterDB::Favorite].each do |klass|
      begin
        if Rails.env.production?
          silent_transaction { klass.import_by!(twitter_user: self) }
        else
          klass.import_by!(twitter_user: self)
        end
      rescue => e
        logger.warn "#{__method__} #{klass}: Continue to saving #{e.class} #{e.message.truncate(100)} #{self.inspect}"
      end
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
