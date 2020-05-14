namespace :twitter do
  namespace :welcome_messages do
    desc 'Create'
    task create: :environment do
      name = ENV['NAME']
      user_id = ENV['USER_ID']
      text = ENV['TEXT'] || File.read(ENV['FILE'])

      client = User.find(user_id).api_client.twitter
      message = client.create_welcome_message(text, name)
      puts "id=#{message.id} text=#{message.text}"
    end

    desc 'List'
    task list: :environment do
      user_id = ENV['USER_ID']

      client = User.find(user_id).api_client.twitter
      client.welcome_message_list.each do |message|
        puts "id=#{message.id} text=#{message.text}"
      end
    end

    desc 'Create a rule'
    task create_rule: :environment do
      user_id = ENV['USER_ID']
      message_id = ENV['MESSAGE_ID']

      client = User.find(user_id).api_client.twitter

      rules = client.welcome_message_rule_list
      puts rules.inspect

      if rules.any?
        client.destroy_welcome_message_rule(*rules.map(&:id))
      end

      puts client.create_welcome_message_rule(message_id)
    end

    desc 'List rules'
    task list_rules: :environment do
      user_id = ENV['USER_ID']

      client = User.find(user_id).api_client.twitter

      client.welcome_message_rule_list.each do |rule|
        puts rule.inspect
      end
    end

    desc 'Destroy rules'
    task destroy_rules: :environment do
      user_id = ENV['USER_ID']

      client = User.find(user_id).api_client.twitter

      rules = client.welcome_message_rule_list
      puts rules.inspect

      if rules.any?
        client.destroy_welcome_message_rule(*rules.map(&:id))
      end
    end
  end
end
