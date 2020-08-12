module SearchCountLimitationHelper

  def too_many_searches_message_on_search_modal(sign_in_url, pricing_url, support_url)
    options = {
        user_signed_in: user_signed_in?,
        user: current_user&.screen_name,
        limit: SearchCountLimitation.max_search_count(current_user),
        sign_in_bonus: SearchCountLimitation::SIGN_IN_BONUS,
        sharing_bonus: SearchCountLimitation.current_sharing_bonus(current_user),
        basic_plan: SearchCountLimitation::BASIC_PLAN,
        price: t('pricing.new.pricing.basic_num'),
        reset_in: SearchCountLimitation.search_count_reset_in_words(user: current_user, session_id: egotter_visit_id),
        sign_in_url: sign_in_url,
        pricing_url: pricing_url,
        support_url: support_url,
        id_hash: SecureRandom.urlsafe_base64(10),
    }

    ERB.new(Rails.root.join('app/views/messages/too_many_searches.ja.html.erb').read).result_with_hash(options)
  end
end
