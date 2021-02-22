class StartPeriodicReportsCreatingRecordsTask
  attr_reader :user_ids

  def initialize(user_ids: nil)
    @user_ids = user_ids
  end

  def start!
    user_ids = initialize_user_ids
    return if user_ids.empty?

    requests = create_requests(user_ids)
    create_jobs(requests)
  end

  def initialize_user_ids
    @user_ids ||= StartPeriodicReportsTask.morning_user_ids
  end

  def create_requests(user_ids)
    max_id = CreateTwitterUserRequest.maximum(:id) || 0

    user_ids.each_slice(1000) do |ids_array|
      requests = User.where(id: ids_array).select(:id, :uid).map do |user|
        CreateTwitterUserRequest.new(
            requested_by: 'batch',
            user_id: user.id,
            uid: user.uid)
      end

      CreateTwitterUserRequest.import requests, validate: false
    end

    CreateTwitterUserRequest.where('id > ?', max_id).where(requested_by: 'batch').select(:id, :user_id)
  end

  def create_jobs(requests)
    requests.each do |request|
      CreateReportTwitterUserWorker.perform_in(rand(3600), request.id)
    end
  end
end
