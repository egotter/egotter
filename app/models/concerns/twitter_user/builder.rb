require 'active_support/concern'

module Concerns::TwitterUser::Builder
  extend ActiveSupport::Concern
  include Concerns::TwitterUser::AssociationBuilder

  class_methods do
    def build_by_user(user)
      TwitterUser.new(
        uid: user.id,
        screen_name: user.screen_name,
        user_info: user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json
      )
    end

    def build_with_relations(user, client:, login_user:, context: nil)
      tu = build_by_user(user)
      tu.build_relations(client, login_user, context)
      tu
    end
  end

  included do
  end
end
