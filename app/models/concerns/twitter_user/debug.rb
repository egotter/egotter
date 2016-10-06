require 'active_support/concern'

module Concerns::TwitterUser::Debug
  extend ActiveSupport::Concern

  class_methods do
    def updatable!(uid)
      redis = Redis.client
      Util::SearchedUidList.new(redis).delete(uid)
      Util::UnauthorizedUidList.new(redis).delete(uid)
      Util::TooManyFriendsUidList.new(redis).delete(uid)

      # TwitterUser.where(uid: uid, user_id: user_id).each do |tu|
      #   tu.update!(created_at: tu.created_at - 1.day, updated_at: tu.updated_at - 1.day)
      # end

      nil
    end
  end

  included do
  end
end
