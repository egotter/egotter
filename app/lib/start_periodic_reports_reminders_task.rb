class StartPeriodicReportsRemindersTask
  def start
    user_ids = StartPeriodicReportsTask.allotted_messages_will_expire_user_ids.uniq.sort
    return if user_ids.empty?

    create_requests(user_ids)
    create_jobs(user_ids)
  end

  def create_requests(user_ids)
    requests = user_ids.map { |user_id| RemindPeriodicReportRequest.new(user_id: user_id) }
    requests.each_slice(1000) do |data|
      RemindPeriodicReportRequest.import data, validate: false
    end
  end

  def create_jobs(user_ids)
    user_ids.each do |user_id|
      CreatePeriodicReportAllottedMessagesWillExpireMessageWorker.perform_async(user_id)
    end
  end
end
