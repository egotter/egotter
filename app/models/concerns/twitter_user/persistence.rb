require 'active_support/concern'
module Concerns::TwitterUser::Persistence
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    # Relations are created on `after_commit` in order to avoid long transaction.
    after_commit(on: :create) do
      start = Time.zone.now

      [TwitterDB::Status, TwitterDB::Mention, TwitterDB::Favorite].each do |klass|
        begin
          klass.import_by!(twitter_user: self)
        rescue => e
          logger.warn "#{__method__} #{klass}: Continue to saving #{e.class} #{e.message.truncate(100)} #{self.inspect}"
        end
      end

      # Set friends_size and followers_size in AssociationBuilder#build_friends_and_followers

      S3::Friendship.import_from!(id, uid, screen_name, @friend_uids)
      S3::Followership.import_from!(id, uid, screen_name, @follower_uids)
      S3::Profile.import_from!(id, uid, screen_name, user_info)

      logger.debug {"#{__method__} #{screen_name} #{Time.zone.now - start}"}

    rescue => e
      # ActiveRecord::RecordNotFound Couldn't find TwitterUser with 'id'=00000
      # ActiveRecord::StatementInvalid Mysql2::Error: Deadlock found when trying to get lock;
      logger.warn "#{__method__}: #{e.class} #{e.message.truncate(120)} #{self.inspect}"
      logger.info e.backtrace.join("\n")
      destroy
    end
  end
end
