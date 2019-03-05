require 'active_support/concern'

module Concerns::Request::Runnable
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
    scope :not_finished, -> user_id do
      where(user_id: user_id, finished_at: nil)
    end
  end

  def finished!
    update!(finished_at: Time.zone.now) if finished_at.nil?
  end

  def finished?
    !finished_at.nil?
  end
end
