require 'active_support/concern'

module Concerns::TwitterUser::Builder
  extend ActiveSupport::Concern
  include Concerns::TwitterUser::AssociationBuilder

  class_methods do
    def build_by_user(user)
      TwitterUser.new(
        uid: user.id,
        screen_name: user.screen_name,
        user_info: TwitterUser.collect_user_info(user)
      )
    end
  end
end
