class ScheduleTweetsReport
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
                              label: I18n.t('quick_replies.shared.label1'),
                              description: I18n.t('quick_replies.shared.description1')
                          },
                      ]
                  }
              }
          }
      }
    end
  end
end
