class CouponsReport
  attr_reader :message, :sender

  def initialize(sender, recipient, message, quick_replies: nil)
    @sender = sender
    @recipient = recipient
    @message = message
    @quick_replies = quick_replies
  end

  def deliver!
    event = self.class.build_direct_message_event(@recipient.uid, @message, @quick_replies)
    @sender.api_client.create_direct_message_event(event: event)
  end

  class << self
    def creation_succeeded_message(user)
      template = Rails.root.join('app/views/coupons/creation_succeeded.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          price: 330,
          pricing_url: Rails.application.routes.url_helpers.pricing_url(og_tag: false),
      )
      new(User.egotter_cs, user, message)
    end

    def build_direct_message_event(uid, message, quick_replies = nil)
      quick_replies ||= [{label: I18n.t('quick_replies.coupons_reports.label1'), description: I18n.t('quick_replies.coupons_reports.description1')}]

      {
          type: 'message_create',
          message_create: {
              target: {recipient_id: uid},
              message_data: {
                  text: message,
                  quick_reply: {
                      type: 'options',
                      options: quick_replies
                  }
              }
          }
      }
    end
  end
end
