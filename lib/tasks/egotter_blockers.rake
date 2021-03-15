namespace :egotter_blockers do
  task destroy: :environment do
    uid = ENV['UID']

    unless (user = User.find_by(uid: uid))
      puts "User not found uid=#{uid}"
      next
    end

    puts "uid=#{uid} screen_name=#{user.screen_name}"

    unless (record = EgotterBlocker.find_by(uid: user.uid))
      puts "EgotterBlocker not found uid=#{uid}"
      next
    end

    begin
      User.egotter.user_timeline(user.uid, count: 1)
      record.destroy
      puts 'Success'
    rescue => e
      puts e.inspect
    end
  end
end
