class DirectMessageEvent
  class << self
    # For debugging
    def build(uid, message)
      {
          type: 'message_create',
          message_create: {
              target: {recipient_id: uid},
              message_data: {
                  text: message,
                  quick_reply: {
                      type: 'options',
                      options: [{label: 'label', description: 'desc'}]
                  }
              }
          }
      }
    end
  end
end
