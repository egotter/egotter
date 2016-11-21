require 'active_support/concern'

module Concerns::Perform
  extend ActiveSupport::Concern

  included do
  end

  def perform(*args)
    super(*args)
  rescue Exception => exception
    rescue_with_handler(exception) || raise
  end
end
