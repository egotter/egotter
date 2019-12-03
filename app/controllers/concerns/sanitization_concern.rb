require 'active_support/concern'

module Concerns::SanitizationConcern
  extend ActiveSupport::Concern

  included do
  end

  SAFE_CONTROLLERS = %w(conversations clusters searches timelines scores tokimeki_unfollow /delete_tweets settings not_found /start)
  SANITIZE_REDIRECT_PATH_REGEXP = Regexp.union(Search::API_V1_NAMES.map(&:to_s) + SAFE_CONTROLLERS)

  # TODO This is incomplete.
  def sanitized_redirect_path(path)
    path.match?(SANITIZE_REDIRECT_PATH_REGEXP) ? path : root_path
  end
end
