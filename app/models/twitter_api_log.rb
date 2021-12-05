# == Schema Information
#
# Table name: twitter_api_logs
#
#  id         :bigint(8)        not null, primary key
#  name       :string(191)
#  created_at :datetime         not null
#
# Indexes
#
#  index_twitter_api_logs_on_created_at  (created_at)
#  index_twitter_api_logs_on_name        (name)
#
class TwitterApiLog < ApplicationRecord
end
