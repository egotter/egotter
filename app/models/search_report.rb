# == Schema Information
#
# Table name: search_reports
#
#  id         :bigint(8)        not null, primary key
#  user_id    :integer          not null
#  read_at    :datetime
#  message_id :string(191)      not null
#  message    :string(191)      default(""), not null
#  token      :string(191)      not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_search_reports_on_created_at  (created_at)
#  index_search_reports_on_token       (token) UNIQUE
#  index_search_reports_on_user_id     (user_id)
#

class SearchReport < ApplicationRecord
  include HasToken
  include Readable

  belongs_to :user

  attr_accessor :searcher_uid

  class << self
    def you_are_searched(searchee_id, searcher_uid = nil)
      new(user_id: searchee_id, token: generate_token, searcher_uid: searcher_uid)
    end

    def report_stopped_message(user)
      template = Rails.root.join('app/views/search_reports/stopped.ja.text.erb')
      ERB.new(template.read).result_with_hash(screen_name: user.screen_name)
    end

    def report_restarted_message(user)
      template = Rails.root.join('app/views/search_reports/restarted.ja.text.erb')
      ERB.new(template.read).result_with_hash(screen_name: user.screen_name)
    end
  end

  def deliver!
    send_start_message
    dm = send_message
    update!(message_id: dm.id, message: dm.truncated_message)
  end

  private

  def send_start_message
    if PeriodicReport.messages_not_allotted?(user)
      user.api_client.create_direct_message_event(User::EGOTTER_UID, start_message)
    end
  end

  def send_message
    event = self.class.build_direct_message_event(user.uid, report_message)
    User.egotter.api_client.create_direct_message_event(event: event)
  end

  def messages_not_allotted?
    !PeriodicReport.messages_allotted?(user) || !PeriodicReport.allotted_messages_left?(user)
  end

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
                              label: I18n.t('quick_replies.search_reports.label1'),
                              description: I18n.t('quick_replies.search_reports.description1')
                          },
                          {
                              label: I18n.t('quick_replies.search_reports.label3'),
                              description: I18n.t('quick_replies.search_reports.description3')
                          },
                          {
                              label: I18n.t('quick_replies.search_reports.label4'),
                              description: I18n.t('quick_replies.search_reports.description4')
                          },
                      ]
                  }
              }
          }
      }
    end
  end

  def start_message
    template = Rails.root.join('app/views/search_reports/start.ja.text.erb')
    ERB.new(template.read).result_with_hash(screen_name: user.screen_name)
  end

  def report_message
    relationship =
        if (searchee = TwitterUser.latest_by(uid: user.uid))
          is_following = searchee.friend_uids.include?(searcher_uid)
          is_follower = searchee.follower_uids.include?(searcher_uid)
          I18n.t("dm.searchNotification.relationship.#{is_following}.#{is_follower}", user: user.screen_name)
        else
          I18n.t('dm.searchNotification.relationship.none')
        end

    template = Rails.root.join('app/views/search_reports/you_are_searched.ja.text.erb')
    ERB.new(template.read).result_with_hash(
        screen_name: user.screen_name,
        relationship: relationship,
        settings_url: Rails.application.routes.url_helpers.settings_url(via: 'search_report', og_tag: 'false'),
        support_url: Rails.application.routes.url_helpers.support_url(via: 'search_report', og_tag: 'false'),
    )
  end

  def timeline_url
    Rails.application.routes.url_helpers.timeline_url(screen_name: user.screen_name, token: token, medium: 'dm', type: 'search', via: 'search_report', og_tag: 'false')
  end
end
