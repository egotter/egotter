require 'statsd'

class FollowEgotterWorker
  include Sidekiq::Worker
  sidekiq_options queue: :egotter, retry: false, backtrace: false

  EGOTTER_UID = 187385226

  def perform(user_id)
    follow(user_id)
  end

  def follow(user_id)
    user = User.find(user_id)
    client = user.api_client
    if client.friendship?(user.uid.to_i, EGOTTER_UID)
      Statsd.new('localhost', 8125).increment('egotter.follow.do_nothing')
    else
      client.follow!(EGOTTER_UID)
      Statsd.new('localhost', 8125).increment('egotter.follow.create')
    end
  rescue => e
    logger.warn "#{e}: #{e.message}"
  end
end
