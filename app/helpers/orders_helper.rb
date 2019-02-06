module OrdersHelper
  def current_plan_name
    if user_signed_in? && current_user.is_subscribing?
      t('pricing.new.xxx_plan', name: t('pricing.new.names.basic'))
    else
      nil
    end
  end
end
