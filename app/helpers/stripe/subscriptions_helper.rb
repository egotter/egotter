module Stripe::SubscriptionsHelper
  def stripe_form_id(plan)
    "plan-#{plan}-form"
  end

  def stripe_btn_id(plan)
    "plan-#{plan}-btn"
  end

  def subscription_period(subscription)
    start, finish =
      case subscription.status
        when 'active'   then [subscription.current_period_start, subscription.current_period_end]
        when 'trialing' then [subscription.trial_start, subscription.trial_end]
        when 'past_due' then [nil, nil]
        when 'canceled' then [nil, nil]
        when 'unpaid'   then [nil, nil]
        else
          logger.warn "#{__method__}: Unknown status #{subscription.status} #{subscription.inspect}"
          [nil, nil]
      end

    return '' if start.nil? || finish.nil?

    start, finish = [start, finish].map { |t| Time.zone.at(t).in_time_zone('Tokyo') }
    "#{l(start, format: :stripe_period)} - #{l(finish, format: :stripe_period)}"
  end

  def plan_subscribed?(plan_key)
    user_signed_in? && current_user.customer&.has_active_plan?(false) &&
      current_user.customer.plan.plan_key == plan_key.to_s
  end

  def subscribe_free_plan_button
    if user_signed_in?
      link_to t('stripe.already_subscribed'), '#', class: 'btn btn-default btn-lg btn-block disabled'
    else
      link_to t('stripe.plans.subscribe_buttons.free'), sign_in_path(via: build_via('free_plan')), class: 'btn btn-default btn-block btn-lg'
    end
  end

  def subscribe_plan_button(plan_key)
    if plan_subscribed?(plan_key)
      link_to t('stripe.already_subscribed'), '#', class: 'btn btn-default btn-lg btn-block disabled'
    else
      render partial: 'stripe/custom_checkout_form', locals: {plan: StripeDB::Plan.find_by(plan_key: plan_key)}
    end
  end

  def card_email(customer)
    customer.sources.data[0].name
  end

  def card_text(customer)
    card = customer.sources.data[0]
    t('stripe.current_plan.card_text', brand: card.brand, last4: card.last4, month: card.exp_month, year: card.exp_year)
  end

  def price_label(plan)
    t('stripe.price_label', amount: plan.amount)
  end

  def subscriptions_form_tag(plan, id:, &block)
    url = current_user&.customer&.has_active_plan? ? stripe_subscription_path(plan_id: plan.plan_id) : stripe_subscriptions_path(plan_id: plan.plan_id)
    method = current_user&.customer&.has_active_plan? ? :patch : :post
    form_tag url, id: id, method: method, &block
  end

  def data_confirm_subscribe(plan)
    {
      title: t('stripe.subscriptions.create.confirm.title'),
      confirm: t('stripe.subscriptions.create.confirm.are_you_sure_order_html', count: plan.trial_period_days, url: specified_commercial_transactions_path),
      commit: t('stripe.subscriptions.create.confirm.commit'),
      cancel: t('stripe.subscriptions.create.confirm.cancel'),
      commit_class: 'btn-success'
    }
  end

  def data_confirm_cancel
    {
      title: t('stripe.subscriptions.destroy.confirm.title'),
      confirm: t('stripe.subscriptions.destroy.confirm.are_you_sure_cancel_html'),
      commit: t('stripe.subscriptions.destroy.confirm.commit'),
      cancel: t('stripe.subscriptions.destroy.confirm.cancel'),
    commit_class: 'btn-danger'
    }
  end
end
