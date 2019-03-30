# == Schema Information
#
# Table name: search_histories
#
#  id            :bigint(8)        not null, primary key
#  session_id    :string(191)      default(""), not null
#  user_id       :integer          not null
#  uid           :bigint(8)        not null
#  ahoy_visit_id :bigint(8)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_search_histories_on_created_at  (created_at)
#  index_search_histories_on_session_id  (session_id)
#  index_search_histories_on_user_id     (user_id)
#

class SearchHistory < ApplicationRecord
  visitable :ahoy_visit

  belongs_to :user, optional: true
  has_one :twitter_db_user, primary_key: :uid, foreign_key: :uid, class_name: 'TwitterDB::User'

  validates :user_id, numericality: {only_integer: true}
  validates :session_id, format: {with: /\A.+\w+.+\Z/}

  include Concerns::Analytics

  def to_param
    screen_name
  end

  def search_logs(duration: 30.minutes)
    SearchLog.where(created_at: (created_at - duration)..created_at).
        where(session_id: session_id).
        order(created_at: :asc)
  end
end
