class DeleteFavoritesReport
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

  module UrlHelpers
    include Rails.application.routes.url_helpers

    def delete_favorites_url(via, og_tag = false)
      super(default_url_options.merge(via: via, og_tag: og_tag))
    end

    def delete_favorites_mypage_url(via)
      super(default_url_options.merge(via: via))
    end

    def default_url_options
      {og_tag: false}
    end
  end
  extend UrlHelpers

  class << self
    def finished_tweet(user, request)
      template = Rails.root.join('app/views/delete_favorites/finished_tweet.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          destroy_count: request.destroy_count,
          url: delete_favorites_url('delete_favorites_finished_tweet', true),
          seconds: (request.updated_at - request.created_at).to_i.to_s(:delimited),
          kaomoji: Kaomoji::KAWAII.sample
      )
      new(nil, nil, message)
    end

    def finished_message(user, request)
      if request.destroy_count > 0
        template = Rails.root.join('app/views/delete_favorites/finished.ja.text.erb')
      else
        template = Rails.root.join('app/views/delete_favorites/not_deleted.ja.text.erb')
      end
      message = ERB.new(template.read).result_with_hash(
          destroy_count: request.destroy_count,
          destroy_limit: DeleteFavoritesRequest::DESTROY_LIMIT,
          mypage_url: delete_favorites_mypage_url('delete_favorites_finished_dm')
      )
      new(User.egotter, user, message)
    end

    def finished_message_from_user(user)
      template = Rails.root.join('app/views/delete_favorites/finished_from_user.ja.text.erb')
      message = ERB.new(template.read).result
      new(user, User.egotter, message)
    end

    def error_message(user)
      template = Rails.root.join('app/views/delete_favorites/not_finished.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(url: delete_favorites_url('delete_favorites_error_dm'))
      new(User.egotter, user, message)
    end

    def send_upload_completed_starting_message(user)
      if PeriodicReport.messages_not_allotted?(user)
        user.api_client.create_direct_message_event(User::EGOTTER_CS_UID, upload_completed_starting_message(user))
      end
    end

    def upload_completed_starting_message(user)
      template = Rails.root.join('app/views/delete_favorites/upload_completed_starting.ja.text.erb')
      ERB.new(template.read).result_with_hash(screen_name: user.screen_name)
    end

    def upload_completed_message(options = {})
      template = Rails.root.join('app/views/delete_favorites/upload_completed.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          url: delete_favorites_url('upload_completed'),
          since_date: options['since'],
          until_date: options['until'],
      )
    end

    def delete_completed_message(user, request_id)
      template = Rails.root.join('app/views/delete_favorites/delete_completed.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          destroy_count: DeleteFavoritesRequest.find(request_id).destroy_count
      )
      new(User.egotter_cs, user, message)
    end

    def build_direct_message_event(uid, message, quick_replies = nil)
      quick_replies ||= [{label: I18n.t('quick_replies.shared.label1'), description: I18n.t('quick_replies.shared.description1')},]

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
