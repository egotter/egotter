module AccountStatusesHelper
  def collect_suspended_uids(client, uids)
    users = client.users(uids).select { |user| !user[:suspended] }
    uids - users.map { |u| u[:id] }
  rescue => e
    TwitterApiStatus.no_user_matches?(e) ? uids : []
  end
end
