module ScoresHelper
  def find_or_create_score(uid)
    score = Score.find_by(uid: uid)

    unless score
      begin
        score = Score.builder(uid).build
        score.save! if score.valid? # It currently validates only klout_id.
      rescue => e
        logger.warn "Score of #{uid} is invalid. #{e.class} #{e.message.truncate(100)}"
      end
    end

    score
  end
end
