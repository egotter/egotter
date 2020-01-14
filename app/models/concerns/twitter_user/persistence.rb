require 'active_support/concern'
module Concerns::TwitterUser::Persistence
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    # There data are created on `after_commit` in order to avoid long transaction.
    after_commit(on: :create) do
      ApplicationRecord.benchmark("Persistence##{__method__} Import data to efs #{id} #{screen_name}", level: :info) do
        Efs::TwitterUser.import_from!(id, uid, screen_name, raw_attrs_text, @friend_uids, @follower_uids)
      end

      # Store data to S3 as soon as possible
      ApplicationRecord.benchmark("Persistence##{__method__} Import data to S3 #{id} #{screen_name}", level: :info) do
        S3::Friendship.import_from!(id, uid, screen_name, @friend_uids, async: true)
        S3::Followership.import_from!(id, uid, screen_name, @follower_uids, async: true)
        S3::Profile.import_from!(id, uid, screen_name, raw_attrs_text, async: true)
      end

      ApplicationRecord.benchmark("Persistence##{__method__} Save relations to RDB #{id} #{screen_name}", level: :info) do
        [::TwitterDB::Status, ::TwitterDB::Mention, ::TwitterDB::Favorite].each do |klass|
          klass.import_by!(twitter_user: self)

          if klass == ::TwitterDB::Favorite
            tweets = favorites.select(&:new_record?).map { |t| t.slice(:uid, :screen_name, :raw_attrs_text) }
            ::S3::FavoriteTweet.import_from!(uid, screen_name, tweets)
          end
        rescue => e
          logger.warn "Persistence##{__method__} #{klass}: Continue to saving #{e.class} #{e.message.truncate(100)} #{self.inspect}"
        end
      end

      # Set friends_size and followers_size in AssociationBuilder#build_friends_and_followers

    rescue => e
      # ActiveRecord::RecordNotFound Couldn't find TwitterUser with 'id'=00000
      # ActiveRecord::StatementInvalid Mysql2::Error: Deadlock found when trying to get lock;
      logger.warn "#{__method__}: #{e.class} #{e.message.truncate(120)} #{self.inspect}"
      logger.info e.backtrace.join("\n")
      destroy
    end
  end
end
