user_info = {}.to_json

ActiveRecord::Base.transaction do
  (1..10).map do |uid|
    TwitterUser.new(uid: uid, screen_name: "sn#{uid}", user_info: user_info, user_id: -1).tap { |u| u.save!(validate: false) }
  end.each do |tu|
    (1..10).each { |uid| tu.friends.create!(uid: uid, screen_name: "sn#{uid}", user_info: user_info) }
    (1..10).each { |uid| tu.followers.create!(uid: uid, screen_name: "sn#{uid}", user_info: user_info) }
    tu.update!(friends_size: tu.friends.size, followers_size: tu.followers.size)
  end
end
