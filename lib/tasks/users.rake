namespace :users do
  desc 'copy unauthorized uids'
  task copy_unauthorized_uids: :environment do
    uids = Util::UnauthorizedUidList.new(Redis.client).to_a
    uids.each_slice(1000).each do |uids_array|
      User.where(uid: uids_array).update_all(authorized: false)
    end
  end
end
