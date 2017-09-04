require 'rails_helper'

RSpec.describe StripeDB::Customer, type: :model do
  let(:stripe_helper) { StripeMock.create_test_helper }

  let(:user) { create(:user) }
  let(:customer) { user.customer }
  let(:stripe_customer) { Stripe::Customer.retrieve(user.customer.customer_id) }
  let(:plan) { StripeDB::Plan.first }
  let(:another_plan) { StripeDB::Plan.second }

  let(:email) { 'a@aaa.com' }
  let(:source) { stripe_helper.generate_card_token }
  let(:metadata) { {} }

  before do
    StripeMock.start
    [%w(basic basic-monthly 14 5), %w(pro pro-monthly 14 10)].each do |plan_key, plan_id, trial_period_days, search_limit|
      plan = stripe_helper.create_plan(id: plan_id, amount: 100)
      StripeDB::Plan.create!(plan_key: plan_key, plan_id: plan.id, name: plan.name, amount: plan.amount, trial_period_days: trial_period_days, search_limit: search_limit)
    end
    user.setup_stripe(email, source, metadata: metadata)
  end

  after { StripeMock.stop }

  describe '#override_source' do

  end

  describe '#subscribe_plan' do
    it 'subscribes a plan' do
      expect(customer).to receive(:retrieve!).with(false).and_return(stripe_customer)
      customer.subscribe_plan(plan.plan_id, metadata: metadata)
      expect(customer.plan_id).to eq(plan.plan_id)
    end

    context 'already have one subscription' do
      before { customer.subscribe_plan(plan.plan_id, metadata: metadata) }

      it 'does nothing' do
        expect(Stripe::Subscription).to_not receive(:create)
        expect { customer.subscribe_plan(plan.plan_id, metadata: metadata) }.to_not change { customer.send(:retrieve!, false).subscriptions.total_count }
      end
    end
  end

  describe '#switch_plan' do
    before { customer.subscribe_plan(plan.plan_id, metadata: metadata) }

    skip 'switches a plan' do
    end

    context 'do not have any subscription' do
      skip 'does nothing' do
      end
    end

    context 'already have specified subscription' do
      skip 'does nothing' do
      end
    end
  end

  describe '#cancel_plan' do

  end

  describe '#has_active_plan?' do

  end
end
