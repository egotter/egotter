module AudienceInsightsHelper
  def friends_chart_data(uid)
    records = FriendsCountPoint.where(uid: uid).order(created_at: :desc).limit(100)
    format_chart_data_points(records)
  end

  def followers_chart_data(uid)
    records = FollowersCountPoint.where(uid: uid).order(created_at: :desc).limit(100)
    format_chart_data_points(records)
  end

  def new_friends_chart_data(uid)
    records = NewFriendsCountPoint.where(uid: uid).order(created_at: :desc).limit(100)
    format_chart_data_points(records)
  end

  private

  def format_chart_data_points(records)
    records.map { |r| [r.created_at.to_i * 1000, r.value] }.reverse
  end
end
