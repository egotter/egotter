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
    ForbiddenUser.where('created_at < ?', 15.minutes.ago).order(created_at: :desc).find_in_batches do |users|
      ForbiddenUser.where(id: users.map(&:id)).delete_all
    end
  rescue => e
    logger.warn "#{e.inspect} options=#{options.inspect}"
  end
end
