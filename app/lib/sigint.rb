class Sigint
  def initialize
    @trapped = false
  end

  def trap(&block)
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      @trapped = true
      yield if block_given?
    end

    self
  end

  def trapped?
    @trapped
  end
end
