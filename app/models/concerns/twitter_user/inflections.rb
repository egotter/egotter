require 'active_support/concern'

module Concerns::TwitterUser::Inflections
  extend ActiveSupport::Concern

  included do
  end

  def mention_name
    "@#{screen_name}"
  end
end