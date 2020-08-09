namespace :coupons do
  desc 'Create'
  task create: :environment do

    if ENV['USER_ID']
      user_id = ENV['USER_ID']
    else
      user_id = User.find_by(screen_name: ENV['SCREEN_NAME']).id
    end

    search_count = ENV['SEARCH_COUNT'] || 3
    expires_at = ENV['EXPIRES_AT'] || 3.hours.since

    Coupon.create!(user_id: user_id, search_count: search_count, expires_at: expires_at)

    if ENV['SEND_DM']
      user = User.find(user_id)
      time = I18n.l(expires_at.in_time_zone('Tokyo'), format: :coupon_short)
      User.egotter.api_client.twitter.create_direct_message(user.uid, I18n.t('dm.add_coupon', count: search_count, time: time))
    end
  end
end
