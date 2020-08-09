namespace :coupons do
  desc 'Create'
  task create: :environment do

    user_id = ENV['USER_ID']
    search_count = ENV['SEARCH_COUNT'] || 3
    expires_at = ENV['EXPIRES_AT'] || 3.hours.since

    Coupon.create!(user_id: user_id, search_count: search_count, expires_at: expires_at)
  end
end
