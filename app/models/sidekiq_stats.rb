class SidekiqStats

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
          size: times.size,
          avg: times.sum / times.size,
          max: times.max,
          min: times.min
      }
    end

    @stats = stats
  end

  def to_s
    @stats.to_s
  end

  def to_h
    @stats
  end
end
