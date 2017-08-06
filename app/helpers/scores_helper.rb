module ScoresHelper
  def find_or_create_score(uid)
    score = Score.find_by(uid: uid)

    unless score
      score = Score.builder(uid).build
      if score.valid? # It currently validates only klout_id.
        begin
          score.save!
        rescue => e
          logger.warn "Score of #{uid} is invalid. #{e.class} #{e.message.truncate(100)}"
        end
      end
    end

    score
  end
end
