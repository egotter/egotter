module TwitterDB
  class Benchmark
    def run
      ::Benchmark.bm(40) do |r|
        perform(r)
        puts
        perform2(r)
        puts
        perform3(r)
      end
    end

    private

    def perform(report)
      t_user = dummy_user
      friends = 1000.times.map { dummy_user }
      followers = 1000.times.map { dummy_user }
      users = []

      report.report 'build all' do
        # users.concat friends.map { |friend| TwitterDB::User.to_import_format(friend) }
        # users.concat followers.map { |follower| TwitterDB::User.to_import_format(follower) }
      end

      # users << TwitterDB::User.to_import_format(t_user)
      users.uniq!(&:first)
      users.sort_by!(&:first)

      friend_ids = friends.map(&:id)
      follower_ids = followers.map(&:id)

      report.report 'save all' do
        ActiveRecord::Base.transaction do
          TwitterDB::User.import_in_batches(users)
        end

        ActiveRecord::Base.transaction do
          TwitterDB::Friendship.import_from!(t_user.id, friend_ids)
          TwitterDB::Followership.import_from!(t_user.id, follower_ids)
          TwitterDB::User.find_by(uid: t_user.id).update!(friends_size: friend_ids.size, followers_size: follower_ids.size)
        end
      end
    end

    def perform2(report)
      t_user = dummy_user
      friends = 1000.times.map { dummy_user }
      followers = 1000.times.map { dummy_user }

      new_user = nil
      report.report 'build all' do
        # new_user = TwitterDB::User.new(TwitterDB::User.to_save_format(t_user))
        # friends.each { |friend| new_user.friends.build(TwitterDB::User.to_save_format(friend)) }
        # followers.each { |follower| new_user.followers.build(TwitterDB::User.to_save_format(follower)) }

        new_user.friends.each.with_index { |friend, i| new_user.friendships.build(friend_uid: friend.uid, sequence: i) }
        new_user.followers.each.with_index { |follower, i| new_user.followerships.build(follower_uid: follower.uid, sequence: i) }
      end

      report.report 'save all' do
        ActiveRecord::Base.transaction do
          new_user.save!
          new_user.friends.each(&:save!)
          new_user.followers.each(&:save!)
          new_user.friendships.each(&:save!)
          new_user.followerships.each(&:save!)
        end
      end
    end

    def perform3(report)
      t_user = dummy_user
      friends = 1000.times.map { dummy_user }
      followers = 1000.times.map { dummy_user }
      client = Object.new
      client.define_singleton_method(:_fetch_parallelly) do |args|
        [t_user, friends, followers]
      end

      new_user = nil
      report.report 'build all' do
        new_user = TwitterDB::User.builder(t_user.id).client(client).build
      end

      report.report 'save all' do
        new_user.persist!
      end
    end

    def dummy_user
      Hashie::Mash.new(id: dummy_uid, screen_name: 'screen_name', user_info: '{}', friends_size: -1, followers_size: -1)
    end

    def dummy_uid
      rand(1_000_000_000)
    end
  end
end

TwitterDB::Benchmark.new.run
