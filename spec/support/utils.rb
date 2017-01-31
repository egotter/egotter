def copy_twitter_user(tu)
  copy = create(:twitter_user, uid: tu.uid, screen_name: tu.screen_name)
  copy.friendships.delete_all
  copy.followerships.delete_all
  tu.friendships.each.with_index { |f, i| copy.friendships.create(from_id: copy.id, friend_uid: f.friend_uid, sequence: i) }
  tu.followerships.each.with_index { |f, i| copy.followerships.create(from_id: copy.id, follower_uid: f.follower_uid, sequence: i) }
  adjust_user_info(copy)
  copy.reload
end

def adjust_user_info(tu)
  json = Hashie::Mash.new(JSON.parse(tu.user_info))
  json.friends_count = tu.friendships.size
  json.followers_count = tu.followerships.size
  tu.user_info = json.to_json
end