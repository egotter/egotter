require 'active_support/concern'

module Concerns::UnfriendsConcern
  extend ActiveSupport::Concern
  include TweetTextHelper

  included do

  end

  def initialize_instance_variables
    singular_name = controller_name.singularize

    @api_path = send("api_v1_#{controller_name}_list_path")
    @breadcrumb_name = singular_name.to_sym
    @canonical_url = send("#{singular_name}_url", @twitter_user)
    @canonical_path = send("#{singular_name}_path", @twitter_user)

    if controller_name == 'unfriends'
      mention_names = @twitter_user.unfriends(limit: 3).map(&:mention_name)
    elsif controller_name == 'unfollowers'
      mention_names = @twitter_user.unfollowers(limit: 3).map(&:mention_name)
    elsif controller_name == 'blocking_or_blocked'
      mention_names = @twitter_user.mutual_unfriends(limit: 3).map(&:mention_name)
    else
      raise "Invalid controller_name value=#{controller_name}"
    end

    @tweet_text_for_empty_users = t('unfriends.show.tweet_empty_text', url: unfriends_top_url(via: current_via('tweet_for_empty')))

    if mention_names.empty?
      @tweet_text = nil
    else
      names = '.' + mention_names.map { |name| honorific_name(name) }.join("\n") + "\n\n"
      @tweet_text = t('.tweet_text', users: names, url: unfriends_top_url(via: current_via('tweet_for_users')))
    end
  end
end
