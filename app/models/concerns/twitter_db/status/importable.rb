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

    def attrs_by(twitter_user:, status:)
      {uid: twitter_user.uid, screen_name: twitter_user.screen_name, raw_attrs_text: collect_raw_attrs(status)}
    end

    def build_by(twitter_user:, status:)
      new(attrs_by(twitter_user: twitter_user, status: status))
    end

    def collect_raw_attrs(status)
      status.symbolize_keys.slice(*Concerns::TwitterDB::Status::RawAttrs::SAVE_KEYS).to_json
    end
  end

  included do
  end
end
