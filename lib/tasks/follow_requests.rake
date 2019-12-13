namespace :follow_requests do
  desc 'Invalidate outdated requests'
  task invalidate_outdated_requests: :environment do

    follower_uids = Bot.api_client.follower_ids('ego_tter')
    puts "follower_uids #{follower_uids.size}"

    requests = FollowRequest.includes(:user).requests_for_egotter
    puts "requests #{requests.size}"

    requests.each do |request|
      if follower_uids.include?(request.user.uid)
        request.update(error_class: FollowRequest::AlreadyFollowing, error_message: 'Updated by rake')
        puts "Updated #{request.id} #{request.user_id} #{request.uid}"
      end
    end
  end
end
