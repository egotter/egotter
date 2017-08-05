module ScoresHelper
  def find_or_create_score(uid)
    score = Score.find_by(uid: uid)

    unless score
      score = Score.builder(uid).build
      begin
        score.save!
      rescue => e
        logger.warn "Score of #{uid} is invalid. #{e.class} #{e.message}"
      end
    end

    score
  end
end
