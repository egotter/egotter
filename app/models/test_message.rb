class TestMessage
  # include Concerns::Report::HasToken
  # include Concerns::Report::HasDirectMessage
  # include Concerns::Report::Readable

  attr_accessor :user, :text

  def initialize(user_id:, text:)
    self.user = User.find(user_id)
    self.text = text
  end

  class << self
    def ok(user_id)
      user = User.find(user_id)
      template = Rails.root.join('app/views/test_reports/ok.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          user: user,
          twitter_user: TwitterUser.latest_by(uid: user.uid),
          timeline_url: timeline_url(user.screen_name),
          settings_url: Rails.application.routes.url_helpers.settings_url(via: 'test_report', og_tag: 'false')
      )

      new(user_id: user_id, text: message)
    end

    def need_fix(user_id, error_class, error_message)
      user = User.find(user_id)
      template = Rails.root.join('app/views/test_reports/need_fix.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          user: user,
          twitter_user: TwitterUser.latest_by(uid: user.uid),
          error_class: error_class,
          error_message: error_message,
          timeline_url: timeline_url(user.screen_name),
          settings_url: Rails.application.routes.url_helpers.settings_url(via: 'test_report', og_tag: 'false')
      )

      new(user_id: user_id, text: message)
    end

    def permission_level_not_enough(user_id)
      template = Rails.root.join('app/views/test_reports/permission_level_not_enough.ja.text.erb')
      message = ERB.new(template.read).result

      new(user_id: user_id, text: message)
    end

    def timeline_url(screen_name)
      Rails.application.routes.url_helpers.timeline_url(screen_name: screen_name, token: ReadConfirmationToken.generate, medium: 'dm', type: 'prompt', via: 'test_report', og_tag: 'false')
    end
  end

  def deliver!(permission_level_not_enough: false)
    if permission_level_not_enough
      dm_client = DirectMessageClient.new(User.egotter.api_client.twitter)
      resp = dm_client.create_direct_message(user.uid, text)
    else
      dm_client = DirectMessageClient.new(user.api_client.twitter)
      dm_client.create_direct_message(User::EGOTTER_UID, I18n.t('dm.testMessage.lets_start'))

      dm_client = DirectMessageClient.new(User.egotter.api_client.twitter)
      resp = dm_client.create_direct_message(user.uid, text)
    end

    DirectMessage.new(resp)
  end
end
