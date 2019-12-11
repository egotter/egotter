# Perform a request and log an error
class CreateFollowTask
  attr_reader :request, :log

  def initialize(request)
    @request = request
  end

  def start!
    @log = CreateFollowLog.create_by(request: request)

    if request.finished?
      log.update(status: false, error_class: FollowRequest::AlreadyFinished)
    else
      request.perform!
      request.finished!
      log.update(status: true)
    end

    self
  rescue => e
    request.update(error_class: e.class, error_message: e.message)
    @log.update(error_class: e.class, error_message: e.message)

    if e.class == FollowRequest::AlreadyFollowing
      records = FollowRequest.where(user_id: request.user_id, uid: request.uid, finished_at: nil, error_class: '')
      if records.exists?
        size = records.size
        records.update_all(error_class: e.class, error_message: 'Bulk update')
        Rails.logger.info "Bulk updated #{size} records #{request.user_id} #{request.uid}"
      end
    end

    raise
  end
end
