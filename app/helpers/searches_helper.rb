module SearchesHelper
  def set_twitter_user
    uid = params.has_key?(:id) ? params[:id].match(/\A\d+\z/)[0].to_i : -1
    if uid.in?([-1, 0])
      logger.warn "#{self.class}##{__method__}: The uid is invalid #{params[:id]} #{current_user_id} #{action_name} #{request.device_type}."
      return redirect_to '/', alert: t('before_sign_in.that_page_doesnt_exist')
    end

    if TwitterUser.exists?(uid: uid, user_id: current_user_id)
      tu = TwitterUser.latest(uid, current_user_id)
      tu.assign_attributes(client: client, egotter_context: 'search')
      @searched_tw_user = tu
    else
      logger.warn "#{self.class}##{__method__}: The TwitterUser doesn't exist #{uid} #{current_user_id} #{action_name} #{request.device_type}."
      redirect_to '/', alert: t('before_sign_in.that_page_doesnt_exist')
    end
  end
end