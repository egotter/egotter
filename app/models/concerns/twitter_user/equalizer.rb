require 'active_support/concern'

module Concerns::TwitterUser::Equalizer
  extend ActiveSupport::Concern

  included do
    def eql?(other)
      self.uid.to_i == other.uid.to_i
    end

    def hash
      self.uid.to_i.hash
    end
  end
end