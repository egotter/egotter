require 'active_support/concern'

module Concerns::TwitterUser::Builder
  extend ActiveSupport::Concern
  include Concerns::TwitterUser::AssociationBuilder

  class_methods do
    def build_by(user:)
      TwitterUser.new(
          uid: user[:id],
          screen_name: user[:screen_name],
          raw_attrs_text: TwitterUser.collect_user_info(user)
      ).tap do |twitter_user|
        if column_names.include?('friends_count') && twitter_user.respond_to?('friends_count=')
          twitter_user.friends_count = user[:friends_count]
        end

        if column_names.include?('followers_count') && twitter_user.respond_to?('followers_count=')
          twitter_user.followers_count = user[:followers_count]
        end
      end
    end
  end
end
