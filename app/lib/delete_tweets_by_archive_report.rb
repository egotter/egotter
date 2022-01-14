class DeleteTweetsByArchiveReport
  attr_reader :message

  def initialize(sender, recipient, message, quick_replies)
    @sender = sender
    @recipient = recipient
    @message = message
    @quick_replies = quick_replies
  end

  def deliver!
    @sender.api_client.send_report(@recipient.uid, @message, @quick_replies)
  end

  class << self
    def delete_started(user)
      template = Rails.root.join('app/views/delete_tweets_by_archive/delete_started.ja.text.erb')
      message = ERB.new(template.read).result_with_hash({})
      new(User.egotter_cs, user, message, [])
    end

    def delete_completed(user, deletions_count)
      template = Rails.root.join('app/views/delete_tweets_by_archive/delete_completed.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          destroy_count: deletions_count
      )
      buttons = [{label: I18n.t('quick_replies.delete_reports.label1'), description: I18n.t('quick_replies.delete_reports.description1')}]
      new(User.egotter_cs, user, message, buttons)
    end

    def no_tweet_found(user)
      template = Rails.root.join('app/views/delete_tweets_by_archive/no_tweet_found.ja.text.erb')
      message = ERB.new(template.read).result_with_hash({})
      buttons = [{label: I18n.t('quick_replies.delete_reports.label1'), description: I18n.t('quick_replies.delete_reports.description1')}]
      new(User.egotter_cs, user, message, buttons)
    end
  end
end
