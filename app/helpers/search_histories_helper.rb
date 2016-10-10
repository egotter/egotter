module SearchHistoriesHelper
  def build_search_histories(user_id)
    return [] if user_id == -1

    uids = BackgroundSearchLog.success_logs(user_id).pluck(:uid).unix_uniq.slice(0, 10)
    records = TwitterUser.where(uid: uids.uniq).map { |tu| [tu.uid.to_i, tu] }.to_h
    TwitterUsersDecorator.new(uids.map { |uid| records[uid.to_i] }.compact).items
  end
end