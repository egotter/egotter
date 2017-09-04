namespace :stripe_db do
  namespace :plans do
    desc 'sync StripeDB::Plan'
    task sync: :environment do

      plan_ids = ENV['PLAN_IDS'] ? ENV['PLAN_IDS'] : %w(test-basic-monthly test-pro-monthly)

      plan_ids.each do |plan_id|
        plan = Stripe::Plan.retrieve(plan_id)
        attrs = plan.to_h.slice(:name, :amount, :trial_period_days)
        attrs.merge!(plan.metadata.to_h.slice(:plan_key, :search_limit))
        StripeDB::Plan.find_or_initialize_by(plan_id: plan_id).update!(attrs)
      end
    end
  end
end
