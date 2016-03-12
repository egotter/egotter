require 'active_support/concern'

module Concerns::TwitterUser::Equalizer
  extend ActiveSupport::Concern

  included do
    def eql?(other)
      unless Rails.env.test?
        raise "#{self.class} is incomparable with #{other.class}" if self.class != other.class
      end

      self.uid.to_i == other.uid.to_i
    end

    def hash
      self.uid.to_i.hash
    end
  end
end