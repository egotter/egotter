class DeleteForbiddenUsersWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'deleting_low', retry: 0, backtrace: false

  def unique_key(options = {})
    -1
  end

  def unique_in
    55.seconds
  end

  def perform(options = {})
    ids_array = []

    ForbiddenUser.where('created_at < ?', 15.minutes.ago).find_in_batches do |users|
      ids_array << users.map(&:id)
    end

    ids_array.each do |ids|
      ForbiddenUser.where(id: ids).delete_all
    end
  rescue => e
    Airbag.warn "#{e.inspect} options=#{options.inspect}"
  end
end
