class StartSendingPromptReportsTask
  def users
    if instance_variable_defined?(:@users)
      @users
    else
      candidates = User.where(id: can_send_ids).select(:id, :uid)
      follower_uids = EgotterFollower.pluck(:uid)
      high, low = candidates.partition {|user| follower_uids.include?(user.uid)}
      @users = high + low
    end
  end

  def authorized_ids
    @authorized_ids ||= User.authorized.pluck(:id)
  end

  def active_ids
    @active_ids ||= User.active(CreatePromptReportRequest::ACTIVE_DAYS).where(id: authorized_ids).pluck(:id)
  end

  def not_blocked_ids
    @not_blocked_ids ||= User.where(id: active_ids).where.not(uid: BlockedUser.pluck(:uid)).pluck(:id)
  end

  def can_send_ids
    @can_send_ids ||= User.can_send_dm.where(id: not_blocked_ids).pluck(:id)
  end

  def ids_stats
    @ids_stats ||= {
        user_ids: User.all.size,
        authorized_ids: authorized_ids.size,
        active_ids: active_ids.size,
        not_blocked_ids: not_blocked_ids.size,
        can_send_ids: can_send_ids.size
    }
  end
end
