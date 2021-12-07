#!/usr/bin/env ruby

def check_data(name, data)
  if data.uniq.size == 1
    puts "#{name} ok: size=#{data[0]}"
  else
    puts "inconsistent #{name}: uids=#{data[0]} users=#{data[1]} in_memory=#{data[2]} efs=#{data[3]} s3=#{data[4]}"
  end
end

def check(user)
  data = [
      user.friend_uids.size,
      TwitterDB::User.where(uid: user.friend_uids).size,
      InMemory::TwitterUser.find_by(user.id)&.friend_uids&.size,
      Efs::TwitterUser.find_by(user.id)&.friend_uids&.size,
      S3::Friendship.find_by(twitter_user_id: user.id)&.friend_uids&.size,
  ]
  check_data(:friend_uids, data)

  data = [
      user.follower_uids.size,
      TwitterDB::User.where(uid: user.follower_uids).size,
      InMemory::TwitterUser.find_by(user.id)&.follower_uids&.size,
      Efs::TwitterUser.find_by(user.id)&.follower_uids&.size,
      S3::Followership.find_by(twitter_user_id: user.id)&.follower_uids&.size,
  ]
  check_data(:follower_uids, data)
  puts ''

  data = [
      user.one_sided_friend_uids.size,
      user.one_sided_friends.size,
  ]
  check_data(:one_sided_friend_uids, data)

  data = [
      user.one_sided_follower_uids.size,
      user.one_sided_followers.size,
  ]
  check_data(:one_sided_follower_uids, data)
  puts ''

  data = [
      user.inactive_friend_uids.size,
      user.inactive_friends.size,
  ]
  check_data(:inactive_friend_uids, data)

  data = [
      user.inactive_follower_uids.size,
      user.inactive_followers.size,
  ]
  check_data(:inactive_follower_uids, data)
  puts ''

  data = [
      user.unfriend_uids.size,
      user.unfriends.size,
  ]
  check_data(:unfriend_uids, data)

  data = [
      user.unfollower_uids.size,
      user.unfollowers.size,
  ]
  check_data(:unfollower_uids, data)
end

def main(twitter_user_id)
  user = TwitterUser.find_by(id: twitter_user_id) || TwitterUser.last
  prev_user = user.previous_version

  puts "twitter_user_id=#{user.id} uid=#{user.uid} screen_name=#{user.screen_name} records=#{TwitterUser.where(uid: user.uid).size} created_at=[#{user.created_at.to_s(:db)}]"
  puts ''
  check(user)
end

if __FILE__ == $0
  main(ENV['TWITTER_USER_ID'])
end
