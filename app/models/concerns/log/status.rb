require 'active_support/concern'

module Concerns::Log::Status
  extend ActiveSupport::Concern

  DEFAULT_SECONDS = Rails.configuration.x.constants['log_recently_created']

  included do
  end

  def processing?
    !recently_created?
  end

  def finished?
    recently_created? && status
  end

  def failed?
    recently_created? && !status
  end

  private

  def recently_created?(seconds = DEFAULT_SECONDS)
    Time.zone.now.to_i - created_at.to_i < seconds
  end

end
