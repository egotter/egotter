class WarningReport
  class << self
    def spam_detected_message
      template = Rails.root.join('app/views/warning_reports/spam_detected.ja.text.erb')
      ERB.new(template.read).result
    end

    def build_direct_message_event(uid, message)
      {
          type: 'message_create',
          message_create: {
              target: {recipient_id: uid},
              message_data: {
                  text: message,
              }
          }
      }
    end
  end
end
