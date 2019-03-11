class SidekiqStats < Hash

  REGEXP = %r{\A(?<time>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z) (\d+) (TID-\w+) (?<worker>\w+) (JID-\w+) INFO: done: (?<running_time>[0-9\.]+) sec\z}

  def initialize(type)
    file = Rails.root.join("log/#{type}.log")
    lines = %x(tail -n 10000 #{file}).each_line.select {|l| l.chomp.match?(REGEXP)}

    matches = lines.map {|l| l.chomp.match(REGEXP)}
    workers = matches.map {|m| m[:worker]}

    stats = {}

    workers.each do |worker|
      times = matches.select {|m| m[:worker] == worker}.map {|m| m[:running_time]}.map(&:to_f)
      stats[worker] = {
          size: sprintf("%3d", times.size),
          avg: sprintf("%.3f", divide(times.sum, times.size)),
          max: sprintf("%.3f", times.max),
          min: sprintf("%.3f", times.min)
      }
    end

    super(stats)
  end

  def divide(num1, num2)
    num1 / num2
  rescue ZeroDivisionError => e
    0
  end

  BUSY_COUNT = 1

  class << self
    def busy?(type)
      process = Sidekiq::ProcessSet.new.find {|p| p['tag'] == "egotter:#{type}"}
      if process
        process['busy'] > BUSY_COUNT
      else
        false
      end
    end
  end
end
