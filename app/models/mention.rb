# == Schema Information
#
# Table name: mentions
#
#  id          :integer          not null, primary key
#  uid         :string(191)      not null
#  screen_name :string(191)      not null
#  status_info :text(65535)      not null
#  from_id     :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_mentions_on_created_at   (created_at)
#  index_mentions_on_from_id      (from_id)
#  index_mentions_on_screen_name  (screen_name)
#  index_mentions_on_uid          (uid)
#

class Mention < ApplicationRecord
  belongs_to :twitter_user

  include Concerns::Status::Store
end
