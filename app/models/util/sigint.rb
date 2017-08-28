module Util
  class Sigint
    def initialize
      @trapped = false
    end

    def trap
      Signal.trap 'INT' do
        puts 'intercept INT and stop ..'
        @trapped = true
      end

      self
    end

    def trapped?
      @trapped
    end
  end
end