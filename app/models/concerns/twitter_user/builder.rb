require 'active_support/concern'

module Concerns::TwitterUser::Builder
  extend ActiveSupport::Concern
  include Concerns::TwitterUser::AssociationBuilder

  class_methods do
    def build_by(user:)
      twitter_user = TwitterUser.new(
          uid: user[:id],
          screen_name: user[:screen_name],
          raw_attrs_text: TwitterUser.collect_user_info(user)
      )

      if twitter_user.respond_to?(:user_info)
        twitter_user.user_info = '{}'
      end

      twitter_user
    end
  end
end
