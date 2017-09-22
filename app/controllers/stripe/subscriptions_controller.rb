class Stripe::SubscriptionsController < ApplicationController

  before_action { redirect_to root_path, notice: t('.comoing_soon') unless stripe_enabled? }

  before_action(except: %i(new)) { require_login! }
  before_action only: %i(create update) do
    redirect_to root_path, alert: t('.bad_request') unless params[:stripeToken].present? && params[:stripeEmail].present?
  end
  before_action only: %i(create update destroy) do
    redirect_to root_path, alert: t('.bad_request') unless StripeDB::Plan.exists?(plan_id: params[:plan_id])
  end
  before_action only: %i(update destroy) do
    redirect_to root_path, alert: t('.bad_request') unless current_user.customer&.subscription
  end

  before_action do
    push_referer
    create_search_log
  end

  rescue_from Exception do |ex|
    logger.warn "#{controller_name}##{action_name}: #{ex.class} #{ex.message} #{current_user.inspect} #{params.inspect}"
    request.xhr? ? head(:internal_server_error) : redirect_to(root_path, alert: friendly_message(ex))
  end

  def new

  end

  def create
    user = current_user
    metadata = build_metadata(user)

    customer = user.customer
    customer ||= user.setup_stripe(params[:stripeEmail], params[:stripeToken], metadata: metadata)
    return redirect_to root_path, alert: t('.payment_processing_failed') if customer.subscription

    sub = customer.subscribe_plan(params[:plan_id], metadata: metadata)
    redirect_to root_path, notice: t('.plan_subscribed_successfully_html', plan: sub.plan.name, url: settings_path)
  end

  def update
    customer = current_user.customer

    if (sub = customer.switch_plan(params[:plan_id]))
      customer.override_source(params[:stripeToken], email: params[:stripeEmail])
      redirect_to root_path, notice: t('.plan_switched_successfully_html', plan: sub.plan.name, url: settings_path)
    else
      redirect_to root_path, alert: t('.plan_already_subscribed', plan: customer.plan.name, url: settings_path)
    end
  end

  def destroy
    if current_user.customer.cancel_plan(params[:plan_id])
      redirect_to root_path, notice: t('.plan_canceled_successfully_html')
    else
      redirect_to root_path, alert: t('.plan_not_subscribed')
    end
  end

  def load
    customer = current_user.customer.retrieve!
    subscription = current_user.customer.subscription
    plan = current_user.customer.plan
    html = render_to_string partial: 'stripe/current_plan', locals: {customer: customer, subscription: subscription, plan: plan}
    render json: {html: html}, status: 200
  end

  private

  def build_metadata(user)
    {uid: user.uid, screen_name: user.screen_name, session_id: fingerprint}
  end

  def friendly_message(ex)
    if ex.message.match /^Keys for idempotent requests can only be used with the same (parameters|endpoint)/
      # Stripe::InvalidRequestError
      t('.duplicate_request', url: settings_path)
    else
      t('.payment_processing_failed')
    end
  end
end
