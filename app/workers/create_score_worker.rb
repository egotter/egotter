class CreateScoreWorker
  include Sidekiq::Worker
  sidekiq_options queue: self, retry: 0, backtrace: false

  def perform(uid, options = {})
    unless Score.exists?(uid: uid)
      score = Score.builder(uid).build
      if score.valid? && !Score.exists?(uid: uid) # It currently validates only klout_id.
        score.save!
      end
    end
  rescue => e
    logger.warn "#{e.class}: #{e.message} #{uid}"
  end
end
