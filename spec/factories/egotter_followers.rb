FactoryBot.define do
  factory :egotter_follower do
    sequence(:uid) { |n| rand(1090286694065070080) }
    sequence(:screen_name) { |n| "t_user_screen_name#{n}" }
  end
end
