# Perform a request and log an error
class DeleteTweetsTask
  attr_reader :request, :retry_in, :log

  def initialize(request)
    @request = request
  end

  def start!
    @log = DeleteTweetsLog.create_by(request: request)

    if request.finished?
      @log.update(error_class: DeleteTweetsRequest::AlreadyFinished, error_message: '')
      return
    end

    e = nil
    begin
      request.perform!
    rescue DeleteTweetsRequest::TweetsNotFound => e
      request.finished!
      request.tweet_finished_message if request.tweet
      SlackClient.delete_tweets.send_message("Finished `#{request.id}` `#{request.tweet}`") rescue nil
      request.send_finished_message(User.egotter)
    rescue DeleteTweetsRequest::Retryable => e
      @retry_in = e.retry_in
    rescue => e
      request.send_error_message(User.egotter)
    else
      raise "#{self.class}##{__method__} DeleteTweetsRequest#perform! must raise an exception #{request.id}"
    ensure
      if e
        @log.assign_attributes(error_class: e.class, error_message: e.message)
        @log.retry_in = e.retry_in if e.respond_to?(:retry_in)
        @log.destroy_count = e.destroy_count if e.respond_to?(:destroy_count)
        @log.save if @log.changed?
      end
    end

    self
  end
end
