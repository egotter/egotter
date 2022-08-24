class BillingPortalSessionWrapper

  def initialize(customer_id)
    configuration = Stripe::BillingPortal::Configuration.create(
        features: {
            customer_update: {enabled: true, allowed_updates: ['email']},
            payment_method_update: {enabled: true},
        },
        business_profile: {
            privacy_policy_url: url_helper.privacy_policy_url,
            terms_of_service_url: url_helper.terms_of_service_url,
        }
    )
    @session = Stripe::BillingPortal::Session.create(customer: customer_id, configuration: configuration.id, return_url: url_helper.settings_url)
  end

  def url
    @session.url
  end

  private

  def url_helper
    @url_helper ||= UrlHelpers.new
  end

  class UrlHelpers
    include Rails.application.routes.url_helpers

    def privacy_policy_url
      super(via: 'customer_portal')
    end

    def terms_of_service_url
      super(via: 'customer_portal')
    end

    def settings_url
      super(via: 'customer_portal')
    end
  end
end
