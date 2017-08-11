module ScoresHelper
  def find_or_create_score(uid)
    score = Score.find_by(uid: uid)

    unless score
      if request.from_crawler? || from_minor_crawler?(request.user_agent)
        score = Score.new(uid: uid, influence_json: {influencers: [], influencees: []}.to_json)
      else
        begin
          score = Score.builder(uid).build
          if score.valid? && !Score.exists?(uid: uid) # It currently validates only klout_id.
            score.save!
          end
        rescue => e
          logger.warn "Score of #{uid} is invalid. #{e.class} #{e.message.truncate(100)}"
        end
      end
    end

    score
  end
end
