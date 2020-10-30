# == Schema Information
#
# Table name: block_reports
#
#  id         :bigint(8)        not null, primary key
#  user_id    :integer          not null
#  message_id :string(191)      default(""), not null
#  message    :string(191)      default(""), not null
#  token      :string(191)      not null
#  read_at    :datetime
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_block_reports_on_created_at  (created_at)
#  index_block_reports_on_token       (token) UNIQUE
#  index_block_reports_on_user_id     (user_id)
#
class BlockReport < ApplicationRecord
  include HasToken
  include Readable

  extend CampaignsHelper

  belongs_to :user

  attr_accessor :blocked_users

  class << self
    def you_are_blocked(user_id, users)
      # Create a message as late as possible
      new(user_id: user_id, token: generate_token, blocked_users: users)
    end

    def report_stopped_message(user)
      template = Rails.root.join('app/views/block_reports/stopped.ja.text.erb')
      ERB.new(template.read).result_with_hash(screen_name: user.screen_name)
    end

    def report_restarted_message(user)
      template = Rails.root.join('app/views/block_reports/restarted.ja.text.erb')
      ERB.new(template.read).result_with_hash(screen_name: user.screen_name)
    end
  end

  def deliver!
    return if send_starting_message_from_user?
    # if send_starting_message_from_user?
    #   user.api_client.create_direct_message_event(User::EGOTTER_UID, self.class.start_message(user))
    # end

    message = self.class.report_message(user, token, blocked_users)
    event = self.class.build_direct_message_event(user.uid, message)
    dm = User.egotter.api_client.create_direct_message_event(event: event)

    update!(message_id: dm.id, message: dm.truncated_message)

    dm
  end

  private

  def send_starting_message_from_user?
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
                              label: I18n.t('quick_replies.block_reports.label1'),
                              description: I18n.t('quick_replies.block_reports.description1')
                          },
                          {
                              label: I18n.t('quick_replies.block_reports.label2'),
                              description: I18n.t('quick_replies.block_reports.description2')
                          },
                          {
                              label: I18n.t('quick_replies.block_reports.label3'),
                              description: I18n.t('quick_replies.block_reports.description3')
                          },
                      ]
                  }
              }
          }
      }
    end

    def report_message(user, token, users)
      url_options = campaign_params('block_report_profile').merge(dialog_params).merge(token: token, medium: 'dm', type: 'block', via: 'block_report')

      template = Rails.root.join('app/views/block_reports/you_are_blocked.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          user: user,
          block_urls: generate_profile_urls(users, url_options, user.add_atmark_to_periodic_report?),
          timeline_url: url_helper.timeline_url(user, url_options),
          settings_url: url_helper.settings_url(url_options),
          faq_url: url_helper.support_url(url_options),
          )
    end

    def start_message(user)
      template = Rails.root.join('app/views/block_reports/start.ja.text.erb')
      ERB.new(template.read).result_with_hash(screen_name: user.screen_name)
    end

    private

    def generate_profile_urls(users, url_options, add_atmark)
      users.map.with_index do |user, i|
        screen_name = user[:screen_name]
        url = url_helper.profile_url({screen_name: screen_name}.merge(url_options))
        "#{'@' if add_atmark || i < 1}#{screen_name} #{url}"
      end
    end

    def url_helper
      @url_helper ||= Rails.application.routes.url_helpers
    end
  end
end
