namespace :onesignal do
  desc 'send'
  task send: :environment do
    user_ids = ENV['USER_IDS']
    next if user_ids.blank?

    user_ids =
      case
        when user_ids.include?('..') then Range.new(*user_ids.split('..').map(&:to_i))
        when user_ids.include?(',') then user_ids.split(',').map(&:to_i)
        else [user_ids.to_i]
      end

    headings = {en: 'Title', ja: 'タイトル'}
    contents = {en: 'Message', ja: 'メッセージ'}
    url = 'https://egotter.com'

    user_ids.each do |user_id|
      start = Time.zone.now
      Onesignal.new(user_id, headings: headings, contents: contents, url: url).send
      puts "#{Time.zone.now}: #{user_id}, #{(Time.zone.now - start).round(1)} seconds"
    end
  end
end
