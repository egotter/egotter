def create_same_record!(tu)
  same_tu = build(:twitter_user, uid: tu.uid, screen_name: tu.screen_name)
  same_tu.friends = tu.friends.map { |f| build(:friend, uid: f.uid, screen_name: f.screen_name) }
  same_tu.followers = tu.followers.map { |f| build(:follower, uid: f.uid, screen_name: f.screen_name) }
  adjust_user_info(same_tu)
  same_tu.save!
  same_tu.friends.each { |f| f.from_id = same_tu.id; f.save! }
  same_tu.followers.each { |f| f.from_id = same_tu.id; f.save! }
  same_tu
end

def adjust_user_info(tu)
  json = Hashie::Mash.new(JSON.parse(ActiveSupport::Gzip.decompress(tu.user_info_gzip)))
  json.friends_count = tu.friends.size
  json.followers_count = tu.followers.size
  tu.user_info_gzip = ActiveSupport::Gzip.compress(json.to_json)
end