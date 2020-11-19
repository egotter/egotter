module ApiLimitationHelper
  def api_list_users_limit
    case controller_name
    when 'blockers'
      if user_signed_in? && current_user.has_valid_subscription?
        Order::BASIC_PLAN_BLOCKERS_LIMIT
      else
        Order::FREE_PLAN_BLOCKERS_LIMIT
      end
    else
      if user_signed_in? && current_user.has_valid_subscription?
        Order::BASIC_PLAN_USERS_LIMIT
      else
        Order::FREE_PLAN_USERS_LIMIT
      end
    end
  end
end
