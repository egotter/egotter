require 'active_support/concern'

module Concerns::TwitterUser::Builder
  extend ActiveSupport::Concern
  include Concerns::TwitterUser::AssociationBuilder

  class_methods do
    def build_by_user(user, user_id, context)
      tu = TwitterUser.new(
        uid: user.id,
        screen_name: user.screen_name,
        user_info: user.slice(*TwitterUser::PROFILE_SAVE_KEYS).to_json,
        user_id: user_id
      )
      tu.egotter_context = context if context
      tu
    end

    def build_with_relations(uid, user_id, client:, context: nil)
      tu = build_by_user(client.user(uid.to_i), user_id, context)
      tu.build_relations(client)
      tu
    end

    def build_without_relations(user, user_id, context: nil)
      build_by_user(user, user_id, context)
    end
  end

  included do
  end
end
