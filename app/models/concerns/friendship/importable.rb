require 'active_support/concern'

module Concerns::Friendship::Importable
  extend ActiveSupport::Concern

  class_methods do
    def import_from!(from_uid, friend_uids)
      friendships = friend_uids.map.with_index {|friend_uid, i| [from_uid.to_i, friend_uid.to_i, i]}

      ActiveRecord::Base.transaction do
        ApplicationRecord.benchmark("#{self.class}#{__method__} delete_all", level: :info) do
          where(from_uid: from_uid).delete_all if exists?(from_uid: from_uid)
        end

        ApplicationRecord.benchmark("#{self.class}#{__method__} import", level: :info) do
          import(%i(from_uid friend_uid sequence), friendships, validate: false, timestamps: false)
        end
      end
    end

    def import_by(twitter_user:)
      import_by!(twitter_user: twitter_user)
    rescue => e
      logger.warn "#{__method__} #{e.class} #{e.message.truncate(100)} #{twitter_user.inspect}"
      logger.info e.backtrace.join("\n")
      []
    end
  end
end