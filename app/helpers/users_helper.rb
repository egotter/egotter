module UsersHelper
  def current_user_id
    @current_user_id ||= user_signed_in? ? current_user.id : -1
  end

  def current_user_uid
    @current_user_uid ||= user_signed_in? ? current_user.uid.to_i : -1
  end

  def current_user_friend_uids
    if instance_variable_defined?(:@current_user_friend_uids)
      @current_user_friend_uids
    else
      user = current_user
      twitter_user = user&.twitter_user

      @current_user_friend_uids =
          if user && twitter_user
            uids = Set.new(twitter_user.friend_uids)
            requests =
                FollowRequest.unprocessed(user.id).where('created_at > ?', twitter_user.created_at).to_a +
                    FollowRequest.finished(user.id).where('created_at > ?', twitter_user.created_at).to_a +
                    UnfollowRequest.unprocessed(user.id).where('created_at > ?', twitter_user.created_at).to_a +
                    UnfollowRequest.finished(user.id).where('created_at > ?', twitter_user.created_at).to_a

            requests.sort_by!(&:created_at)

            requests.each do |req|
              if req.class == FollowRequest
                uids.add(req.uid)
              else
                uids.subtract([req.uid])
              end
            end

            uids.to_a
          else
            []
          end
    end
  end

  def current_user_is_following?(uid)
    current_user_friend_uids.include? uid.to_i
  end

  def current_user_friend_screen_names
    if instance_variable_defined?(:@current_user_friend_screen_names)
      @current_user_friend_screen_names
    else
      @current_user_friend_screen_names = (current_user&.twitter_user&.friends&.pluck(:screen_name) || [])
    end
  end

  def current_user_friend_screen_names_rendered?
    if instance_variable_defined?(:@current_user_friend_screen_names_rendered)
      @current_user_friend_screen_names_rendered
    else
      @current_user_friend_screen_names_rendered = true
      false
    end
  end

  def admin_signed_in?
    user_signed_in? && current_user.admin?
  end
end
