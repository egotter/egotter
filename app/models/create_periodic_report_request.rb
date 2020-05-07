# == Schema Information
#
# Table name: create_periodic_report_requests
#
#  id          :bigint(8)        not null, primary key
#  user_id     :integer          not null
#  status      :string(191)      default(""), not null
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

  attr_accessor :check_interval

  def perform!
    if check_interval && interval_too_short?
      update(status: 'interval_too_short')
      CreatePeriodicReportMessageWorker.perform_async(user_id, interval_too_short: true)
    else
      CreatePeriodicReportMessageWorker.perform_async(user_id, build_report_options)
    end
  end

  PERIOD_DURATION = 1.day

  def build_report_options
    start_date = PERIOD_DURATION.ago
    end_date = Time.zone.now

    # TODO Use TwitterUser#unfriend_uids
    builder = UnfriendsBuilder.new(user.uid, start_date: start_date, end_date: end_date)
    unfriends = TwitterDB::User.where_and_order_by_field(uids: builder.unfriends.flatten.take(10)).map(&:screen_name)
    unfollowers = TwitterDB::User.where_and_order_by_field(uids: builder.unfollowers.flatten.take(10)).map(&:screen_name)

    {
        request_id: id,
        start_date: start_date,
        end_date: end_date,
        unfriends: unfriends,
        unfollowers: unfollowers
    }
  end

  INTERVAL = 1.hour

  def interval_too_short?
    last_request = CreatePeriodicReportRequest.where(user_id: user_id).
        where(status: '').
        where.not(finished_at: nil).
        where.not(id: id).
        order(created_at: :desc).
        first

    if last_request
      last_request.finished_at > INTERVAL.ago
    else
      false
    end
  end
end
