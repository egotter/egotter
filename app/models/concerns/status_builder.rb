require 'active_support/concern'

module StatusBuilder
  extend ActiveSupport::Concern

  class_methods do
    def build_by(twitter_user:, status:)
      new(attrs_by(twitter_user: twitter_user, status: status))
    end

    private

    def attrs_by(twitter_user:, status:)
      {uid: twitter_user.uid, screen_name: twitter_user.screen_name, raw_attrs_text: collect_raw_attrs(status)}
    end

    def collect_raw_attrs(status)
      status.symbolize_keys.slice(*StatusAccessor::SAVE_KEYS).to_json
    end
  end
end
