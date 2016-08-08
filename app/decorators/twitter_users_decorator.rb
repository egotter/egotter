class TwitterUsersDecorator < Draper::CollectionDecorator
  def items
    me = h.current_user_id
    targets = object.map do |u|
      {target: u, friendship: friendships.include?(u.uid.to_i), me: (u.uid.to_i == me)}
    end
    Kaminari.paginate_array(targets).page(h.params[:page]).per(25)
  end

  private

  def friendships
    @_friendships ||=
      if h.user_signed_in? && h.current_user.twitter_user?
        h.current_user.twitter_user.friend_uids
      else
        []
      end
  end
end
