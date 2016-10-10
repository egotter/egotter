FactoryGirl.define do
  factory :twitter_user do
    sequence(:uid) { |n| n }
    screen_name 'sn'
    user_info_gzip { ActiveSupport::Gzip.compress({id: uid, screen_name: screen_name, protected: true}.to_json) }
    user_id -1

    after(:build) do |tu|
      tu.friends = 2.times.map { build(:friend) }
      tu.followers = 2.times.map { build(:follower) }
      tu.statuses = 2.times.map { build(:status) }
      tu.mentions = 2.times.map { build(:mention) }
      tu.favorites = 2.times.map { build(:favorite) }

      json = Hashie::Mash.new(JSON.parse(ActiveSupport::Gzip.decompress(tu.user_info_gzip)))
      json.friends_count = tu.friends.size
      json.followers_count = tu.followers.size
      tu.user_info_gzip = ActiveSupport::Gzip.compress(json.to_json)
    end
  end
end
