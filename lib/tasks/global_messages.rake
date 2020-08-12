namespace :global_messages do
  desc 'Add'
  task add: :environment do
    text = ENV['TEXT']
    GlobalMessage.create!(text: text)
  end
end
