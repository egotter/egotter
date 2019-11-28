#!/usr/bin/env ruby

CMD = [
    'cd /var/egotter',
    'git pull origin master',
    'bundle install --path .bundle --without test development',
    'RAILS_ENV=production bundle exec rake assets:precompile',
    'sudo service puma restart',
].join(' && ')

[3, 5, 7].each do |id|
  host = "egotter_web#{id}"
  puts "#{host} #{CMD}"

  %x(ssh #{host} "#{CMD}").each_line do |line|
    puts "#{host} #{line}"
  end

  3.times do
    seconds = 10
    puts "Sleep in #{seconds} seconds."
    sleep seconds
  end
end

%x(git tag deploy-#{Time.now.to_i})
%x(git push origin --tags)