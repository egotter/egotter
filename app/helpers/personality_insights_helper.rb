module PersonalityInsightsHelper
  def analysis_accuracy(word_count)
    if word_count >= 6000
      t('personality_insights.show.accuracy.very_strong');
    elsif word_count > 3500
      t('personality_insights.show.accuracy.strong');
    elsif word_count > 1500
      t('personality_insights.show.accuracy.decent');
    else
      t('personality_insights.show.accuracy.weak');
    end
  end

  def personality_insight_score_details(trait)
    score = sprintf('%d', trait['raw_score'] * 100)
    percentile = (trait['percentile'] > 0.5 ? t('personality_insights.traits.from_top') : t('personality_insights.traits.from_bottom')) + sprintf('%d', percentile_inverse(trait['percentile']))
    deviation = percentile_to_deviation(trait['percentile'])
    t('personality_insights.traits.score_details', score: score, percentile: percentile, deviation: deviation)
  end

  def personality_insight_description_details(trait)
    if trait['percentile'] > 0.5
      t("personality_insights.traits.trait_high_descriptions.#{trait['trait_id']}")
    else
      t("personality_insights.traits.trait_low_descriptions.#{trait['trait_id']}")
    end
  end

  def personality_insight_to_upper_case(trait_id)
    trait_id.split('_').slice(1..).join('-').capitalize
  end

  # All traits with percentage values between 32% and 68% are inside the common people.
  def personality_insight_low_agreeableness?(insight)
    insight.agreeableness_trait['percentile'] < 0.18
  end

  def personality_insight_very_low_agreeableness?(insight)
    insight.agreeableness_trait['percentile'] < 0.10
  end

  def personality_insight_high_neuroticism?(insight)
    insight.neuroticism_trait['percentile'] > 0.68
  end

  def personality_insight_very_high_neuroticism?(insight)
    insight.neuroticism_trait['percentile'] > 0.90
  end

  private

  def percentile_to_deviation(value)
    values = DEVIATION_TO_PERCENTILE.map { |_, v| (value * 100 - v).abs }
    DEVIATION_TO_PERCENTILE[values.index(values.min)][0]
  end

  def percentile_inverse(value)
    ((value > 0.5) ? (1 - value) : value) * 100
  end

  DEVIATION_TO_PERCENTILE = [
      [83, 100.0],
      [82, 99.9],
      [81, 99.9],
      [80, 99.9],
      [79, 99.8],
      [78, 99.7],
      [77, 99.7],
      [76, 99.5],
      [75, 99.4],
      [74, 99.2],
      [73, 98.9],
      [72, 98.6],
      [71, 98.2],
      [70, 97.7],
      [69, 97.1],
      [68, 96.4],
      [67, 95.5],
      [66, 94.5],
      [65, 93.3],
      [64, 91.9],
      [63, 90.3],
      [62, 88.5],
      [61, 86.4],
      [60, 84.1],
      [59, 81.6],
      [58, 78.8],
      [57, 75.8],
      [56, 72.6],
      [55, 69.1],
      [54, 65.5],
      [53, 61.8],
      [52, 57.9],
      [51, 54.0],
      [50, 50.0],
      [49, 46.0],
      [48, 42.1],
      [47, 38.2],
      [46, 34.5],
      [45, 30.9],
      [44, 27.4],
      [43, 24.2],
      [42, 21.2],
      [41, 18.4],
      [40, 15.9],
      [39, 13.6],
      [38, 11.5],
      [37, 9.7],
      [36, 8.1],
      [35, 6.7],
      [34, 5.5],
      [33, 4.5],
      [32, 3.6],
      [31, 2.9],
      [30, 2.3],
      [29, 1.8],
      [28, 1.4],
      [27, 1.1],
      [26, 0.8],
      [25, 0.6],
      [24, 0.5],
      [23, 0.3],
      [22, 0.3],
      [21, 0.2],
      [20, 0.1],
      [19, 0.1],
      [18, 0.1],
      [17, 0.0]
  ]
end
