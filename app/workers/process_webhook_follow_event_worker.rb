require 'digest/md5'

class ProcessWebhookFollowEventWorker
  include Sidekiq::Worker
  prepend TimeoutableWorker
  sidekiq_options queue: 'webhook', retry: 0, backtrace: false

  def unique_key(event, options = {})
    Digest::MD5.hexdigest(event.inspect)
  end

  def unique_in
    3.seconds
  end

  def after_skip(*args)
    Airbag.info "The job of #{self.class} is skipped args=#{args.inspect}"
  end

  def timeout_in
    10.seconds
  end

  # options:
  def perform(event, options = {})
    if event['type'] == 'follow'
      EgotterFollower.import_uids([event['source']['id']])
    elsif event['type'] == 'unfollow'
      EgotterFollower.delete_uids([event['source']['id']])
    else
      Airbag.info "event is not follow event_type=#{event['type']}"
      return
    end
  rescue => e
    Airbag.exception e, event: event
  end
end
