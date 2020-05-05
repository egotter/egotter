# == Schema Information
#
# Table name: warning_messages
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
#  index_warning_messages_on_created_at  (created_at)
#  index_warning_messages_on_token       (token) UNIQUE
#  index_warning_messages_on_user_id     (user_id)
#

class WarningMessage < ApplicationRecord
  include Concerns::Report::HasToken
  include Concerns::Report::HasDirectMessage
  include Concerns::Report::Readable

  belongs_to :user

  class << self
    def inactive_message(user_id)
      user = User.find(user_id)
      token = generate_token

      template = Rails.root.join('app/views/warning_messages/inactive.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          last_access_at: I18n.l(user.last_access_at.in_time_zone('Tokyo'), format: :prompt_report_short),
          timeline_url: timeline_url(screen_name: user.screen_name, token: token, medium: 'dm', type: 'warning', follow_dialog: 1, share_dialog: 1, via: 'inactive_warning'),
          settings_url: Rails.application.routes.url_helpers.settings_url(via: 'inactive_warning', og_tag: 'false'),
      )
      new(user_id: user_id, message: message, token: token)
    end

    def not_following_message(user_id)
      user = User.find(user_id)
      token = generate_token

      template = Rails.root.join('app/views/warning_messages/not_following.ja.text.erb')
      message = ERB.new(template.read).result_with_hash(
          timeline_url: timeline_url(screen_name: user.screen_name, token: token, medium: 'dm', type: 'warning', follow_dialog: 1, share_dialog: 1, via: 'not_following_warning'),
          settings_url: Rails.application.routes.url_helpers.settings_url(via: 'not_following_warning', og_tag: 'false'),
      )
      new(user_id: user_id, message: message, token: token)
    end

    def timeline_url(*args)
      Rails.application.routes.url_helpers.timeline_url(*args)
    end

    def inactive_additional_warning(user_id)
      user = User.find(user_id)
      template = Rails.root.join('app/views/warning_messages/inactive_additional_warning.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          timeline_url: timeline_url(screen_name: user.screen_name, follow_dialog: 1, share_dialog: 1, via: 'inactive_warning'),
      )
    end

    def not_following_additional_warning(user_id)
      user = User.find(user_id)
      template = Rails.root.join('app/views/warning_messages/not_following_additional_warning.ja.text.erb')
      ERB.new(template.read).result_with_hash(
          timeline_url: timeline_url(screen_name: user.screen_name, follow_dialog: 1, share_dialog: 1, via: 'not_following_warning'),
      )
    end
  end

  def deliver!
    dm = User.egotter.api_client.create_direct_message_event(event: {
        type: 'message_create',
        message_create: {
            target: {recipient_id: user.uid},
            message_data: {
                text: message,
                quick_reply: {
                    type: 'options',
                    options: [
                        {
                            label: I18n.t('quick_replies.continue.label'),
                            description: I18n.t('quick_replies.continue.description')
                        },
                        {
                            label: I18n.t('quick_replies.revive.label'),
                            description: I18n.t('quick_replies.revive.description')
                        },
                        {
                            label: I18n.t('quick_replies.followed.label'),
                            description: I18n.t('quick_replies.followed.description')
                        }
                    ]
                }
            }
        }
    })
    update!(message_id: dm.id, message: dm.truncated_message)
    dm
  end
end
