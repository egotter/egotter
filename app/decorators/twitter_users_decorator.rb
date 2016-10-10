class TwitterUsersDecorator < Draper::CollectionDecorator
  def items
    if h.user_signed_in?
      user = h.current_user
      friend_uids = user.twitter_user&.friend_uids
      friend_uids = [] if friend_uids.nil?
    else
      user = User.new
      friend_uids = []
    end

    targets = object.map do |tu|
      {target: tu, friendship: friend_uids.include?(tu.uid.to_i), me: (tu.uid.to_i == user.uid.to_i)}
    end
    Kaminari.paginate_array(targets).page(h.params[:page]).per(25)
  end
end
