namespace :coupons do
  desc 'Create'
  task create: :environment do

    users = []

    ENV['UIDS'].split(',').each do |uid|
      user = User.where(authorized: true).find_by(uid: uid)
      if user
        users << user
      else
        puts "#{uid} is not found"
      end
    end

    search_count = ENV['SEARCH_COUNT'] || 3
    expires_at = ENV['EXPIRES_AT'] || 3.hours.since

    users.each do |user|
      Coupon.create!(user_id: user.id, search_count: search_count, expires_at: expires_at)

      if ENV['SEND_DM']
        time = I18n.l(expires_at.in_time_zone('Tokyo'), format: :coupon_short)
        begin
          User.egotter.api_client.twitter.create_direct_message(user.uid, I18n.t('dm.add_coupon', count: search_count, time: time))
        rescue => e
          puts "#{e.inspect} user_id=#{user.id}"
        end
      end
    end
  end
end
