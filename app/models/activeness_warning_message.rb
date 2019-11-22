# == Schema Information
#
# Table name: activeness_warning_messages
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
#  index_activeness_warning_messages_on_created_at  (created_at)
#  index_activeness_warning_messages_on_token       (token) UNIQUE
#  index_activeness_warning_messages_on_user_id     (user_id)
#

class ActivenessWarningMessage < ApplicationRecord
  include Concerns::Report::HasToken
  include Concerns::Report::HasDirectMessage
  include Concerns::Report::Readable

  belongs_to :user

  class << self
    def warn(user_id)
      new(user_id: user_id, token: generate_token)
    end
  end

  def deliver!
    template = Rails.root.join('app/views/prompt_reports/activeness_warning.ja.text.erb')
    message = ERB.new(template.read).result_with_hash(
        last_access_at: I18n.l(user.last_access_at.in_time_zone('Tokyo'), format: :prompt_report_short),
        timeline_url: Rails.application.routes.url_helpers.timeline_url(screen_name: user.screen_name, token: token, medium: 'dm', type: 'warning', follow_dialog: 1, share_dialog: 1, via: 'prompt_report_activeness_warning')
    )

    dm_client = DirectMessageClient.new(User.egotter.api_client.twitter)
    resp = dm_client.create_direct_message(user.uid, message)

    dm = DirectMessage.new(resp)
    update!(message_id: dm.id, message: dm.truncated_message)

    dm
  end
end
