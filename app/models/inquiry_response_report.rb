class InquiryResponseReport
  class << self
    def build_direct_message_event(uid, message)
      {
          type: 'message_create',
          message_create: {
              target: {recipient_id: uid},
              message_data: {
                  text: message,
                  quick_reply: {
                      type: 'options',
                      options: [
                          {
                              label: I18n.t('quick_replies.inquiry_response_reports.label1'),
                              description: I18n.t('quick_replies.inquiry_response_reports.description1')
                          },
                          {
                              label: I18n.t('quick_replies.inquiry_response_reports.label2'),
                              description: I18n.t('quick_replies.inquiry_response_reports.description2')
                          },
                      ]
                  }
              }
          }
      }
    end
  end
end
