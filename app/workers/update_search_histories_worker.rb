class UpdateSearchHistoriesWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(session_id, user_id, uid)
    condition = (user_id.to_s == '-1') ? {session_id: session_id} : {user_id: user_id}
    latest = SearchHistory.order(created_at: :desc).find_by(condition)

    if !latest || latest.uid.to_i != uid.to_i
      values = {session_id: session_id, user_id: user_id, uid: uid}
      if user_id.to_s != '-1'
        user = User.find(user_id)
        values.merge!(plan_id: user.customer.plan_id) if user.customer&.has_active_plan?
      end
      SearchHistory.create!(values)
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{user_id} #{uid}"
  end
end
