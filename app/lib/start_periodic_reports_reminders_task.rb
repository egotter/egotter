class StartPeriodicReportsRemindersTask
  attr_reader :user_ids

  def start!
    user_ids = initialize_user_ids
    return if user_ids.empty?

    create_requests(user_ids)
    create_jobs(user_ids)
  end

  def initialize_user_ids
    @user_ids = StartPeriodicReportsTask.allotted_messages_will_expire_user_ids.uniq
  end

  def create_requests(user_ids)
    requests = user_ids.map { |user_id| RemindPeriodicReportRequest.new(user_id: user_id) }
    requests.each_slice(1000) do |data|
      RemindPeriodicReportRequest.import data, validate: false
    end
  end

  def create_jobs(user_ids)
    user_ids.each.with_index do |user_id, i|
      CreatePeriodicReportAllottedMessagesWillExpireMessageWorker.perform_in(i.seconds, user_id)
    end
  end
end
