class NginxStats

  TIME_REGEXP = Regexp.new(1.minute.ago.strftime("%Y-%m-%dT%H:%M:\\d{2}\\+00:00"))
  LINE_REGEXP = %r{^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3} .+? .+? (?<time>\[.+?\]) "(?<path>GET /timelines/\w+.+?)" \d{3} \d+ ".+?" ".+?" "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" "(?<ratio>.+?)" "(?<req>.+?)"(?: "(?<upstream>.+?)" "(?<rack>.+?)")?$}

  def initialize
    # file = '/var/log/nginx/access.log'
    file = 'access.log'
    lines = %x(tail -n 10000 #{file}).each_line.select {|l| l.chomp.match?(LINE_REGEXP)}

    matches = lines.map {|l| l.chomp.match(LINE_REGEXP)}

    times = matches.map do |match|
      {req: match[:req].to_f, upstream: match[:upstream].to_f, rack: match[:rack].to_f}
    end

    stats = {}
    size = times.size

    stats['/timelines/show'] = {
        size: size,
        req: sprintf("%.3f", divide(times.map {|t| t[:req]}.sum, size)),
        upstream: sprintf("%.3f", divide(times.map {|t| t[:upstream]}.sum, size)),
        rack: sprintf("%.3f", divide(times.map {|t| t[:rack]}.sum, size))
    }

    @stats = stats
  end

  def divide(num1, num2)
    num1 / num2
  rescue ZeroDivisionError => e
    0
  end

  def to_s
    @stats.to_s
  end

  def to_h
    @stats
  end
end
