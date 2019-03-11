require 'active_support/concern'

module Concerns::Log::Runnable
  extend ActiveSupport::Concern

  class_methods do
  end

  included do
  end

  def finished!(message = 'Finished')
    update(status: true, message: message)
  end

  def failed!(error_class, error_message)
    update(message: '', error_class: error_class, error_message: error_message)
  end
end
