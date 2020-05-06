# == Schema Information
#
# Table name: create_periodic_report_requests
#
#  id          :bigint(8)        not null, primary key
#  user_id     :integer          not null
#  finished_at :datetime
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_create_periodic_report_requests_on_created_at  (created_at)
#  index_create_periodic_report_requests_on_user_id     (user_id)
#

class CreatePeriodicReportRequest < ApplicationRecord
  include Concerns::Request::Runnable
  belongs_to :user

  validates :user_id, presence: true

  def perform!
    CreatePeriodicReportMessageWorker.perform_async(user_id, build_report_options)
  end

  PERIOD_DURATION = 1.day

  def build_report_options
    start_date = PERIOD_DURATION.ago
    end_date = Time.zone.now

    builder = UnfriendsBuilder.new(user.uid, start_date: start_date, end_date: end_date)
    unfriends = TwitterDB::User.where_and_order_by_field(uids: builder.unfriends.flatten).map(&:screen_name)
    unfollowers = TwitterDB::User.where_and_order_by_field(uids: builder.unfollowers.flatten).map(&:screen_name)

    {
        request_id: id,
        start_date: start_date,
        end_date: end_date,
        unfriends: unfriends,
        unfollowers: unfollowers
    }
  end
end
