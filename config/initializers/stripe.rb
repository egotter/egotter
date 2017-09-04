Stripe.api_key = ENV['STRIPE_SECRET_KEY']
Stripe.log_level = Stripe::LEVEL_INFO
Stripe.max_network_retries = 2 # Idempotency keys are automatically added.