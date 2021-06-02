namespace :coupons do
  desc 'Create'
  task create: :environment do

    uids = []

    if ENV['UIDS']
      uids = ENV['UIDS'].split(',').map(&:to_i)
    elsif ENV['TWEET_ID']
      uids = Bot.api_client.twitter.retweeters_ids(ENV['TWEET_ID']).to_hash[:ids]
    end

    if uids.empty?
      raise "Set UIDS or TWEET_ID"
    end

    users = []

    uids.each do |uid|
      user = User.where(authorized: true).find_by(uid: uid)
      if user
        users << user
      else
        puts "There is no user with an UID of #{uid}"
      end
    end

    if users.empty?
      raise "There are no users"
    else
      puts "Found #{users.size} users"
    end

    search_count = ENV['SEARCH_COUNT'] || 3
    expires_at = ENV['EXPIRES_AT'] || 3.hours.since

    users.each do |user|
      Coupon.create!(user_id: user.id, search_count: search_count, expires_at: expires_at)

      if ENV['SEND_DM']
        time = I18n.l(expires_at.in_time_zone('Tokyo'), format: :coupon_short)
        begin
          User.egotter.api_client.twitter.create_direct_message(user.uid, I18n.t('dm.add_coupon', count: search_count, time: time))
          puts "DM is sent user_id=#{user.id}"
        rescue => e
          puts "#{e.inspect} user_id=#{user.id}"
        end
      end
    end
  end

  task add_stripe_coupon: :environment do
    user = ENV['USER_ID'] ? User.find(ENV['USER_ID']) : User.find_by(uid: ENV['UID'])
    coupon = Stripe::Coupon.retrieve(ENV['STRIPE_COUPON_ID'])
    expires_at = ENV['EXPIRES_AT'] ? Time.zone.parse(ENV['EXPIRES_AT']) : 7.days.since

    puts "user=#{user.screen_name}"
    puts "amount_off=#{coupon.amount_off}"
    puts Coupon.add_stripe_coupon!(user, coupon.id, expires_at).inspect
  end

  task send_dm: :environment do
    user = ENV['USER_ID'] ? User.find(ENV['USER_ID']) : User.find_by(screen_name: ENV['SCREEN_NAME'])
    dry_run = ENV['DRY_RUN']

    report = CouponsReport.creation_succeeded_message(user)
    report.deliver! unless dry_run
    puts report.message
  end
end
