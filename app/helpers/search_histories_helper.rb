module SearchHistoriesHelper
  def build_search_histories
    if user_signed_in?
      user_id = current_user_id
      searched_uids = BackgroundSearchLog.success_logs(user_id, 20).pluck(:uid).unix_uniq.slice(0, 10)
      key = lambda { |uid| "#{uid}-#{user_id}" }
      records = searched_uids.each_with_object({}) do |uid, memo|
        unless memo.has_key?(key.call(uid))
          memo[key.call(uid)] = TwitterUser.latest(uid.to_i, user_id)
        end
      end
      build_user_items(searched_uids.map { |uid| records[key.call(uid)] }.compact)
    else
      []
    end
  end
end