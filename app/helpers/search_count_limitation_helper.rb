module SearchCountLimitationHelper

  def search_count_limitation_too_many_searches_message(sign_in_url, pricing_url, support_url)
    values = {
        limit: SearchCountLimitation.max_search_count(current_user),
        sign_in_bonus: SearchCountLimitation::SIGN_IN_BONUS,
        sharing_bonus: SearchCountLimitation::SHARING_BONUS,
        basic_plan: SearchCountLimitation::BASIC_PLAN,
        reset_in: SearchCountLimitation.search_count_reset_in_words(user: current_user, session_id: egotter_visit_id),
        sign_in_url: sign_in_url,
        pricing_url: pricing_url,
        support_url: support_url,
        id_hash: SecureRandom.urlsafe_base64(10),
    }

    if user_signed_in?
      t('after_sign_in.too_many_searches_html', values)
    else
      t('before_sign_in.too_many_searches_html', values)
    end
  end
end
