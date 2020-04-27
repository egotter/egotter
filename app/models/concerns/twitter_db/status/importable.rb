require 'active_support/concern'

module Concerns::TwitterDB::Status::Importable
  extend ActiveSupport::Concern

  class_methods do
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
