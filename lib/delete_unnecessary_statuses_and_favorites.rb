class DeleteUnnecessaryStatusesAndFavorites
  def run
    start = Time.zone.now
    uids = TwitterUser.pluck(:uid)
    puts "uids #{uids.size} #{uids.uniq.size} (#{Time.zone.now - start}s)"

    start = Time.zone.now
    selected_uids = uids.group_by { |x| x }.map { |k, v| [k, v.count] }.select { |_k, v| v > 2 }
    puts "selected_uids #{selected_uids.size} #{selected_uids.uniq.size} (#{Time.zone.now - start}s)"


    start = Time.zone.now
    deleted_statuses = 0
    cur_deleted_statuses = 0
    deleted_favorites = 0
    cur_deleted_favorites = 0
    selected_uids.each.with_index do |(uid, _count), i|
      twitter_users = TwitterUser.where(uid: uid).order(created_at: :desc).drop(1)
      twitter_users.each do |tu|
        if tu.statuses.any?
          cur_deleted_statuses += tu.statuses.size
          tu.statuses.delete_all
        end
        if tu.favorites.any?
          cur_deleted_favorites += tu.favorites.size
          tu.favorites.delete_all
        end
      end

      if (i != 0 && i % 100 == 0) || i == selected_uids.size - 1
        puts "deleted #{cur_deleted_statuses} #{cur_deleted_favorites} (#{Time.zone.now - start}s)"
        deleted_statuses += cur_deleted_statuses
        deleted_favorites += cur_deleted_favorites
        start = Time.zone.now
        cur_deleted_statuses = 0
        cur_deleted_favorites = 0
      end
    end

    puts "deleted(all) #{deleted_statuses} #{deleted_favorites} (#{Time.zone.now - start}s)"
  end
end
