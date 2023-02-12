namespace :global_messages do
  task add: :environment do
    text = ENV['TEXT']
    GlobalMessage.create!(text: text)
    GlobalMessage::Cache.set(text)
  end

  task del: :environment do
    id = ENV['ID'] || GlobalMessage.order(created_at: :desc).first.id
    GlobalMessage.find(id).update(expires_at: Time.zone.now)
    GlobalMessage::Cache.del
  end
end
