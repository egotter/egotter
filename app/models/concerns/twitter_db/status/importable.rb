require 'active_support/concern'

module Concerns::TwitterDB::Status::Importable
  extend ActiveSupport::Concern

  class_methods do
    def import_from!(uid, screen_name, statuses)
      statuses = statuses.map.with_index {|status, i| [uid, screen_name, status.raw_attrs_text, i]}

      transaction do
        where(uid: uid).delete_all if exists?(uid: uid)
        import!(%i(uid screen_name raw_attrs_text sequence), statuses, validate: false)
      end
    end
  end

  included do
  end
end
