require 'active_support/concern'

module Concerns::FriendsConcern
  extend ActiveSupport::Concern

  included do

  end

  def initialize_instance_variables
    @api_path = send("api_v1_#{controller_name}_list_path")
    @canonical_url = send("#{controller_name.singularize}_url", @twitter_user)

    counts = view_context.current_counts(@twitter_user)

    @tweet_text = t('.tweet_text', {user: @twitter_user.mention_name, url: @canonical_url}.merge(counts))
  end
end
