namespace :bots do
  task invalidate_credentials: :environment do
    verbose = ENV['VERBOSE']

    if StopServiceFlag.on?
      Airbag.info 'StopServiceFlag: bots:invalidate_credentials is stopped'
      next
    end

    Bot.where(enabled: true).find_each do |bot|
      bot.invalidate_credentials
      print '.' if verbose
      sleep 0.5
    end
  end
end
