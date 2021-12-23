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

    def build_with_replies(uid, message, replies)
      {
          type: 'message_create',
          message_create: {
              target: {recipient_id: uid},
              message_data: {
                  text: message,
                  quick_reply: {
                      type: 'options',
                      options: replies
                  }
              }
          }
      }
    end

    # For debugging
    # media_id = client.send(:chunk_upload, File.open(...), 'image/png', 'dm_image')[:media_id]
    def build_with_media(uid, message, media_id)
      {
          type: 'message_create',
          message_create: {
              target: {recipient_id: uid},
              message_data: {text: message, attachment: {type: 'media', media: {id: media_id}}}
          }
      }
    end
  end
end
