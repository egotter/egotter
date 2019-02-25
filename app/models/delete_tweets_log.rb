# == Schema Information
#
# Table name: delete_tweets_logs
#
#  id            :integer          not null, primary key
#  error_class   :string(191)      default(""), not null
#  error_message :string(191)      default(""), not null
#  message       :string(191)      default(""), not null
#  status        :boolean          default(FALSE), not null
#  created_at    :datetime         not null
#  request_id    :integer          default(-1), not null
#  user_id       :integer          default(-1), not null
#
# Indexes
#
#  index_delete_tweets_logs_on_created_at  (created_at)
#

class DeleteTweetsLog < ApplicationRecord
end
