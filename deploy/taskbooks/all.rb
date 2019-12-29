require_relative '../lib/deploy_ruby'
Dir['./deploy/taskbooks/*_task.rb'].each { |file| require file }
