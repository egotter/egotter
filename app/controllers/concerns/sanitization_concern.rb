require 'active_support/concern'

module SanitizationConcern
  extend ActiveSupport::Concern

  SAFE_REDIRECT_PATHS = %w(
      /searches
      /timelines
      /clusters
      /delete_tweets
      /delete_favorites
      /settings
      /start
      /personality_insights
      /audience_insights
      /profiles
      /access_confirmations
      /follow_confirmations
  )
  SAFE_REDIRECT_PATH_REGEXP = Regexp.union(((Search::API_V1_NAMES.map { |n| "/#{n}" } + SAFE_REDIRECT_PATHS)).uniq)

  def sanitized_redirect_path(path)
    !path.match?(/http/) && path.length < 600 && path.match?(SAFE_REDIRECT_PATH_REGEXP) ? path : root_path(via: current_via('sanitization_failed'))
  end
end
