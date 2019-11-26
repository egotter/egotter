#!/usr/bin/env ruby

CMD="cd /var/egotter && git pull origin master && bundle install --path .bundle --without test development && RAILS_ENV=production bundle exec rake assets:precompile && sudo service puma restart"

[3, 5, 7].each do |id|
  host = "egotter_web#{id}"
  %x(ssh #{host} "#{CMD}").each_line do |line|
    puts "#{host} #{line}"
  end
  sleep 30
end
