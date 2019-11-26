#!/usr/local/bin/ruby

CMD="cd /var/egotter && git pull origin master && bundle install --path .bundle --without test development && RAILS_ENV=production bundle exec rake assets:precompile && sudo service puma restart"

[3, 5, 8].each do |id|
  puts %x(ssh egotter_web#{id} "#{CMD}")
  sleep 30
end
