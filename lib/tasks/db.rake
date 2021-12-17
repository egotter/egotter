if Rails.env.test?
  Rake::Task['db:migrate:reset'].enhance do
    path = Rails.root.join('config', 'groupdate.sql')
    cmd = "mysql -u #{ENV['EGOTTER_DATABASE_USERNAME']} -h #{ENV['EGOTTER_DATABASE_HOST']} egotter_test < #{path}"
    puts "Run: #{cmd}"
    %x(#{cmd})
  end
end
