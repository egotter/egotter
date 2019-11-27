require 'active_support/concern'

module Concerns::Followership::Importable
  extend ActiveSupport::Concern

  class_methods do
    def import_from!(from_uid, follower_uids)
      followerships = follower_uids.map.with_index {|follower_uid, i| [from_uid.to_i, follower_uid.to_i, i]}

      ActiveRecord::Base.transaction do
        where(from_uid: from_uid).delete_all if exists?(from_uid: from_uid)
        import(%i(from_uid follower_uid sequence), followerships, validate: false, timestamps: false)
      end
    end
  end
end