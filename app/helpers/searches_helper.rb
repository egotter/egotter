module SearchesHelper
  def set_twitter_user
    uid = params.has_key?(:id) ? params[:id].match(/\A\d+\z/)[0].to_i : -1
    if uid.in?([-1, 0])
      logger.info "#{self.class}##{__method__}: The uid is invalid #{params[:id]} #{current_user_id} #{action_name} #{request.device_type}."
      return redirect_to '/', alert: t('before_sign_in.that_page_doesnt_exist')
    end

    if TwitterUser.exists?(uid: uid, user_id: current_user_id)
      tu = TwitterUser.latest(uid, current_user_id)
      tu.assign_attributes(client: client, egotter_context: 'search')
      @searched_tw_user = tu
    else
      logger.info "#{self.class}##{__method__}: The TwitterUser doesn't exist #{uid} #{current_user_id} #{action_name} #{request.device_type}."
      redirect_to '/', alert: t('before_sign_in.that_page_doesnt_exist')
    end
  end

  def fetch_twitter_user_from_cache(uid, user_id)
    attrs = ValidTwitterUserSet.new(redis).get(uid, user_id)
    return nil if attrs.nil?

    TwitterUser.new(
      uid: attrs['uid'],
      screen_name: attrs['screen_name'],
      user_id: attrs['user_id'],
      user_info: attrs['user_info'],
      egotter_context: 'search'
    )
  end

  def reject_crawler
    if request.device_type == 'crawler'
      logger.warn "#{self.class}##{__method__}: The crawler is rejected."
      render text: t('before_sign_in.that_page_doesnt_exist')
    end
  end

  def build_user_items(items)
    current_user_friends =
      if user_signed_in? && current_user.twitter_user?
        current_user.twitter_user.friend_uids
      else
        []
      end
    me = current_user_id
    targets = items.map { |u| {target: u, friendship: current_user_friends.include?(u.uid.to_i), me: (u.uid.to_i == me)} }
    Kaminari.paginate_array(targets).page(params[:page]).per(25)
  end
end