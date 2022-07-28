class ImportMutingRelationshipsWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'creating_low', retry: 0, backtrace: false

  def unique_key(user_id, options = {})
    user_id
  end

  def unique_in
    3.minutes
  end

  def delay_in
    30.minutes + rand(12).hours
  end

  # options:
  def perform(user_id, options = {})
    user = User.find(user_id)
    collected_uids = MutingRelationship.update_all_mutes(user)
    return if collected_uids.blank?

    CreateTwitterDBUsersForMissingUidsWorker.push_bulk(collected_uids, user_id, enqueued_by: self.class)

    collected_uids.each_slice(1000) do |uids_array|
      User.authorized.where(uid: uids_array).each do |user|
        CreateMuteReportWorker.perform_in(delay_in, user.id)
      end
    end
  rescue => e
    Airbag.exception e, user_id: user_id, options: options
  end
end
