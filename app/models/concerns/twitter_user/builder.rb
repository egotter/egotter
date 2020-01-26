require 'active_support/concern'

module Concerns::TwitterUser::Builder
  extend ActiveSupport::Concern
  include Concerns::TwitterUser::AssociationBuilder

  class_methods do
    def build_by(user:)
      TwitterUser.new(
          uid: user[:id],
          screen_name: user[:screen_name],
          friends_count: user[:friends_count],
          followers_count: user[:followers_count],
          profile_text: Concerns::TwitterUser::Builder.filter_save_keys(user)
      )
    end
  end

  module_function

  def filter_save_keys(user)
    user.symbolize_keys.slice(*Concerns::TwitterUser::Profile::SAVE_KEYS).to_json
  end
end
