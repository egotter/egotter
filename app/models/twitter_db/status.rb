# == Schema Information
#
# Table name: twitter_db_statuses
#
#  id             :bigint(8)        not null, primary key
#  uid            :bigint(8)        not null
#  screen_name    :string(191)      not null
#  sequence       :integer          not null
#  raw_attrs_text :text(65535)      not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_twitter_db_statuses_on_created_at   (created_at)
#  index_twitter_db_statuses_on_screen_name  (screen_name)
#  index_twitter_db_statuses_on_uid          (uid)
#

# TODO Remove this class
module TwitterDB
  class Status < ApplicationRecord
    belongs_to :user, primary_key: :uid, foreign_key: :uid, class_name: 'TwitterDB::User', optional: true

    include Concerns::TwitterDB::Status::RawAttrs
    include Concerns::TwitterDB::Status::Importable
  end
end
