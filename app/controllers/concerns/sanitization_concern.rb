require 'active_support/concern'

module Concerns::SanitizationConcern
  extend ActiveSupport::Concern

  SAFE_CONTROLLERS = %w(
      clusters searches
      timelines
      scores
      tokimeki_unfollow
      /delete_tweets
      settings
      not_found
      /start
      /personality_insights
      /audience_insights
      /profiles
  )

  SANITIZE_REDIRECT_PATH_REGEXP = Regexp.union(Search::API_V1_NAMES.map(&:to_s) + SAFE_CONTROLLERS)

  def sanitized_redirect_path(path)
    !path.match?(/http/) && path.length < 100 && path.match?(SANITIZE_REDIRECT_PATH_REGEXP) ? path : root_path
  end
end
