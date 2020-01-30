# == Schema Information
#
# Table name: create_welcome_message_logs
#
#  id            :bigint(8)        not null, primary key
#  user_id       :integer          default(-1), not null
#  request_id    :integer          default(-1), not null
#  uid           :bigint(8)        default(-1), not null
#  screen_name   :string(191)      default(""), not null
#  status        :boolean          default(FALSE), not null
#  error_class   :string(191)      default(""), not null
#  error_message :string(191)      default(""), not null
#  created_at    :datetime         not null
#
# Indexes
#
#  index_create_welcome_message_logs_on_created_at   (created_at)
#  index_create_welcome_message_logs_on_request_id   (request_id)
#  index_create_welcome_message_logs_on_screen_name  (screen_name)
#  index_create_welcome_message_logs_on_uid          (uid)
#

class CreateWelcomeMessageLog < ApplicationRecord
  before_validation do
    if self.error_message
      self.error_message = self.error_message.truncate(180)
    end
  end

  def update_by(exception:)
    update(
        status: false,
        error_class: exception.class,
        error_message: exception.message
    )
  end
end
