class DirectMessageEvent
  class << self
    def build(uid, message, replies = nil)
      attrs = {
          type: 'message_create',
          message_create: {
              target: {recipient_id: uid},
              message_data: {text: message}
          }
      }

      if replies
        attrs[:message_create][:message_data][:quick_reply] = {
            type: 'options',
            options: replies
        }
      end

      attrs
    end
  end
end
