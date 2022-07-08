FactoryBot.define do
  factory :unfriend_user do
    friends_count { rand(100) }
    followers_count { rand(100) }
    add_attribute(:protected) { false }
    suspended { false }
    account_created_at { 1.day.ago }
    statuses_count { rand(100) }
    favourites_count { rand(100) }
    listed_count { rand(100) }
    sequence(:name) { |n| "name-#{n}" }
    sequence(:location) { |n| "location-#{n}" }
    sequence(:description) { |n| "description-#{n}" }
    sequence(:url) { |n| "https://example.com/url-#{n}" }
    verified { false }
    sequence(:profile_image_url) { |n| "https://example.com/profile_image_url-#{n}" }
  end
end
