require 'active_support'
require 'active_support/core_ext'
require 'datadog/statsd'

re_time = Regexp.new(1.minute.ago.strftime("%Y-%m-%dT%H:%M:\\d{2}\\+00:00"))
re_line = %r{^\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3} .+? .+? (?<time>\[.+?\]) "(?<path>GET /search_results.+?)" \d{3} \d+ ".+?" ".+?" "\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}" "(?<ratio>.+?)" "(?<req>.+?)"(?: "(?<upstream>.+?)" "(?<rack>.+?)")?$}
response_times = []

File.open('/var/log/nginx/access.log') do |f|
  response_times =
    f.each_line.lazy.select { |line| line.match(re_time) }.first(1000).map do |line|
      m = line.match(re_line)
      m ? [m[:req] || '-1', m[:upstream] || '-1', m[:rack] || '-1'] : nil
    end.compact
end

Datadog::Statsd.new('localhost', 8125).batch do |s|
  response_times.each do |req, upstream, rack|
    s.histogram('egotter.nginx.request_time', req.to_f) if req != '-1'
    s.histogram('egotter.nginx.upstream_response_time', upstream.to_f) if upstream != '-1'
    s.histogram('egotter.nginx.sent_http_x_runtime', rack.to_f) if rack != '-1'
  end
end
