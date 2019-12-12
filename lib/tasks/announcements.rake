namespace :announcements do
  desc 'Add'
  task add: :environment do
    sigint = Util::Sigint.new.trap

    text = ENV['TEXT']
    rotate = ENV['ROTATE'] == 'false' ? false : true

    Announcement.create!(date: Time.zone.now.in_time_zone('Tokyo').to_date.strftime('%Y/%m/%d'), message: text)
    Announcement.order(created_at: :asc).first.update(status: false) if rotate
  end
end
