require 'active_support/concern'

module Concerns::TwitterDB::User::Importable
  extend ActiveSupport::Concern

  class_methods do
    def import_by!(twitter_user:)
      user = find_or_initialize_by(uid: twitter_user.uid)
      user.assign_attributes(screen_name: twitter_user.screen_name, user_info: twitter_user.user_info)
      user.assign_attributes(friends_size: -1, followers_size: -1) if user.new_record?
      user.save!
    end

    def import_by(twitter_user:)
      import_by!(twitter_user: twitter_user)
    rescue ActiveRecord::RecordInvalid => e
      logger.warn "#{__method__}: #{e.class} #{e.message} #{e.record.inspect} #{twitter_user.inspect}"
      logger.info e.backtrace.join("\n")
    rescue => e
      logger.warn "#{__method__}: #{e.class} #{e.message} #{twitter_user.inspect}"
      logger.info e.backtrace.join("\n")
    end
  end

  included do
  end
end
