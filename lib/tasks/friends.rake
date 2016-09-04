namespace :friends do
  desc 'add user_info_gzip'
  task add_user_info_gzip: :environment do
    ActiveRecord::Base.connection.execute('ALTER TABLE friends ADD user_info_gzip BLOB NOT NULL AFTER user_info')
  end

  desc 'compress user_info'
  task compress_user_info: :environment do
    Friend.find_in_batches(batch_size: 1000) do |friends_array|
      friends = friends_array.map do |f|
        [f.id, '', '', '', ActiveSupport::Gzip.compress(f.user_info), 0]
      end
      Friend.import(%i(id uid screen_name user_info user_info_gzip from_id), friends, on_duplicate_key_update: %i(user_info_gzip), validate: false)
    end
  end

  desc 'remove user_info'
  task remove_user_info: :environment do
    Friend.find_in_batches(batch_size: 1000) do |friends_array|
      friends = friends_array.map do |f|
        [f.id, '', '', '', '', 0]
      end
      Friend.import(%i(id uid screen_name user_info user_info_gzip from_id), friends, on_duplicate_key_update: %i(user_info), validate: false)
    end
  end

  desc 'import'
  task import: :environment do
    sigint = false
    Signal.trap 'INT' do
      puts 'intercept INT and stop ..'
      sigint = true
    end

    Rails.logger.silence do
      Friend.find_in_batches(batch_size: 5000) do |friends_array|
        friends = friends_array.map do |f|
          [f.id, f.uid, f.screen_name, ActiveSupport::Gzip.compress(f.user_info), f.from_id, f.created_at]
        end
        TmpFriend.import(%i(id uid screen_name user_info_gzip from_id created_at), friends, validate: false)
        puts "#{Time.zone.now}: #{friends.first[0]} - #{friends.last[0]}"

        break if sigint
      end
    end
  end
end