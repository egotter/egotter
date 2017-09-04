module StripeDB
  class Customer < ActiveRecord::Base
    belongs_to :user, primary_key: :uid, foreign_key: :uid

    with_options dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_one :plan, primary_key: :plan_id, foreign_key: :plan_id, class_name: 'StripeDB::Plan'
    end

    validates :uid, uniqueness: true
    validates :customer_id, uniqueness: true

    def override_source(source_id, email: nil)
      cu = retrieve!(false)
      cu.email = email if email.present?
      cu.source = source_id
      cu.save
    end

    def subscribe_plan(plan_id, metadata:)
      if has_no_subscriptions?
        trial_days = StripeDB::Plan.find_by(plan_id: plan_id).trial_period_days
        values = {customer: customer_id, items: [{plan: plan_id}], tax_percent: 8.0, trial_period_days: trial_days, metadata: metadata}
        sub = Stripe::Subscription.create(values)
        update!(plan_id: extract_plan_id(sub))
        sub
      end
    end

    def switch_plan(plan_id)
      if has_one_subscription? && has_one_item? && !has_same_plan?(plan_id)
        sub = subscription
        sub.items = [{id: extract_item_id(sub), plan: plan_id}]
        sub.save
        update!(plan_id: extract_plan_id(sub))
        sub
      end
    end

    def cancel_plan(plan_id)
      if has_one_subscription? && has_one_item? && has_same_plan?(plan_id)
        sub = subscription
        sub.delete(at_period_end: false)
        update!(plan_id: nil)
        sub
      end
    end

    def has_active_plan?(cache = true)
      if cache
        plan_id.present? && !!plan
      else
        retrieve!(false)
        sub = subscription
        case [plan_id.nil?, (sub && %w(active trialing).include?(sub.status) && plan_id == extract_plan_id(sub))]
          when [true, true]
            logger.warn "##{__method__}: Invalid state #{self.inspect} #{sub.inspect}"
            false
          when [true, false]  then false
          when [false, true]  then true
          when [false, false] then false
        end
      end
    end

    def subscription
      retrieve!.subscriptions.data[0]
    end

    def retrieve!(cache = true)
      if cache && instance_variable_defined?(:@retrieve)
        @retrieve
      else
        @retrieve = Stripe::Customer.retrieve(customer_id)
      end
    end

    private

    def has_one_subscription?
      retrieve!(false).subscriptions.total_count == 1
    end

    def has_no_subscriptions?
      retrieve!(false).subscriptions.total_count == 0
    end

    def has_one_item?
      subscription.items.total_count == 1
    end

    def has_same_plan?(plan_id)
      sub = subscription
      sub.plan.id == plan_id && extract_plan_id(sub) == plan_id
    end

    def extract_item_id(sub)
      sub.items.data[0].id
    end

    def extract_plan_id(sub)
      sub.items.data[0].plan.id
    end
  end
end
