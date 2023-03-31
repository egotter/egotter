module PricingHelper
  def plan_display_name(id)
    if id == 'subscription'
      t('pricing.plans.subscription')
    elsif Order::BASIC_PLAN_MONTHLY_BASIS.include?(id)
      if id == 'monthly-basis-1'
        t('pricing.plans.month1')
      elsif id == 'monthly-basis-3'
        t('pricing.plans.month3')
      elsif id == 'monthly-basis-6'
        t('pricing.plans.month6')
      elsif id == 'monthly-basis-12'
        t('pricing.plans.month12')
      end
    else
      raise "invalid id value=#{id}"
    end
  end

  def plan_display_price(id)
    if id == 'subscription'
      t('pricing.plans.subscription_price_html', regular: Order::REGULAR_PRICE_TAX_INCLUDED, discount: Order::DISCOUNT_PRICE_TAX_INCLUDED)
    elsif Order::BASIC_PLAN_MONTHLY_BASIS.include?(id)
      if id == 'monthly-basis-1'
        t('pricing.plans.price_html', value: Order::BASIC_PLAN_MONTHLY_BASIS_TAX_INCLUDED[id].to_s(:delimited))
      else
        t('pricing.plans.discounted_price_html', regular: Order::BASIC_PLAN_MONTHLY_BASIS_REGULAR_TAX_INCLUDED[id].to_s(:delimited), discount: Order::BASIC_PLAN_MONTHLY_BASIS_TAX_INCLUDED[id].to_s(:delimited))
      end
    else
      raise "invalid id value=#{id}"
    end
  end

  def plan_display_image(id)
    if id == 'subscription'
      image_path('/images/plan_subscription.png')
    elsif Order::BASIC_PLAN_MONTHLY_BASIS.include?(id)
      if id == 'monthly-basis-1'
        image_path('/images/plan_month1.png')
      elsif id == 'monthly-basis-3'
        image_path('/images/plan_month3.png')
      elsif id == 'monthly-basis-6'
        image_path('/images/plan_month6.png')
      elsif id == 'monthly-basis-12'
        image_path('/images/plan_month12.png')
      end
    else
      raise "invalid id value=#{id}"
    end
  end

  def plan_description(id)
    if id == 'subscription'
      t('pricing.plans.descriptions.subscription_html', trial_days: Order::TRIAL_DAYS)
    elsif Order::BASIC_PLAN_MONTHLY_BASIS.include?(id)
      if id == 'monthly-basis-1'
        t('pricing.plans.descriptions.one_month_html', num: 1)
      elsif id == 'monthly-basis-3'
        t('pricing.plans.descriptions.multiple_months_html', num: 3, discount_percent: 3)
      elsif id == 'monthly-basis-6'
        t('pricing.plans.descriptions.multiple_months_html', num: 6, discount_percent: 5)
      elsif id == 'monthly-basis-12'
        t('pricing.plans.descriptions.multiple_months_html', num: 12, discount_percent: 10)
      end
    else
      raise "invalid id value=#{id}"
    end
  end

  def plan_months_count(id)
    if Order::BASIC_PLAN_MONTHLY_BASIS.include?(id)
      id.split('-')[-1].to_i
    else
      raise "invalid id value=#{id}"
    end
  end

  def new_plan_preorder_url
    'https://egotter.com/l/new_plan'
  end
end
