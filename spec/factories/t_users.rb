FactoryBot.define do
  factory :t_user, class: Hashie::Mash do
    sequence(:id) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "t_user_screen_name#{n}" }
    sequence(:friends_count) { |n| rand(1000) }
    sequence(:followers_count) { |n| rand(1000) }
    sequence(:protected) { |n| n % 2 == 0 }
    sequence(:suspended) { |n| n % 8 == 0 }
    sequence(:status) { |n| {created_at: (n % 9 + 1).minutes.ago.round} }
    sequence(:created_at) { |n| (n % 9 + 10).minutes.ago.round }
    sequence(:statuses_count) { |n| rand(1000) }
    sequence(:favourites_count) { |n| rand(1000) }
    sequence(:listed_count) { |n| rand(1000) }
    sequence(:name) { |n| "t_user_name#{n}" }
    location { 'Japan' }
    description { 'Hi.' }
    url { 'https://example.com' }
    sequence(:geo_enabled) { |n| n % 2 == 0 }
    sequence(:verified) { |n| n % 8 == 0 }
    lang { 'ja' }
    profile_image_url_https { 'https://profile.image' }
    profile_banner_url { 'https://https://profile.banner' }
    profile_link_color { '123456' }
  end
end
