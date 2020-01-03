# == Schema Information
#
# Table name: create_twitter_user_logs
#
#  id            :bigint(8)        not null, primary key
#  user_id       :integer
#  request_id    :integer
#  uid           :bigint(8)
#  status        :boolean          default(FALSE), not null
#  error_class   :string(191)
#  error_message :string(191)
#  created_at    :datetime         not null
#
# Indexes
#
#  index_create_twitter_user_logs_on_created_at  (created_at)
#  index_create_twitter_user_logs_on_request_id  (request_id)
#  index_create_twitter_user_logs_on_uid         (uid)
#  index_create_twitter_user_logs_on_user_id     (user_id)
#

class CreateTwitterUserLog < ApplicationRecord
  before_validation do
    if self.error_message
      self.error_message = self.error_message.truncate(150)
    end
  end

  class << self
    def create_by(request:)
      create(
          user_id: request.user&.id,
          request_id: request.id,
          uid: request.uid,
      )
    end
  end
end
