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

  attr_accessor :check_interval, :check_credentials, :check_twitter_user
  attr_accessor :worker_context
  attr_accessor :sync_flag

  def perform!
    logger.debug { "#{self.class}##{__method__} check_interval=#{check_interval} check_credentials=#{check_credentials} check_twitter_user=#{check_twitter_user} worker_context=#{worker_context} sync_flag=#{sync_flag}" }

    if check_credentials && !verify_credentials_before_starting?
      return
    end

    if check_interval && !check_interval_before_starting?
      return
    end

    if check_twitter_user
      create_new_twitter_user_record
    end

    if sync_flag
      CreatePeriodicReportMessageWorker.new.perform(user_id, build_report_options)
    else
      # If an administrator makes a request immediately after processing a user's request, it may be skipped
      jid = CreatePeriodicReportMessageWorker.perform_async(user_id, build_report_options)
      update(status: 'message_skipped') unless jid
    end
  end

  def verify_credentials_before_starting?
    user.api_client.verify_credentials
    true
  rescue => e
    logger.info "#{self.class}##{__method__} #{e.inspect} request=#{self.inspect}"
    update(status: 'unauthorized')

    if user_or_egotter_requested_job?
      if sync_flag
        CreatePeriodicReportMessageWorker.new.perform(user_id, unauthorized: true)
      else
        jid = CreatePeriodicReportMessageWorker.perform_async(user_id, unauthorized: true)
        update(status: 'unauthorized,message_skipped') unless jid
      end
    end

    false
  end

  def check_interval_before_starting?
    if self.class.interval_too_short?(include_user_id: user_id, reject_id: id)
      update(status: 'interval_too_short')

      if user_or_egotter_requested_job?
        if sync_flag
          CreatePeriodicReportMessageWorker.new.perform(user_id, interval_too_short: true)
        else
          jid = CreatePeriodicReportMessageWorker.perform_async(user_id, interval_too_short: true)
          update(status: 'interval_too_short,message_skipped') unless jid
        end
      end

      false
    else
      true
    end
  end

  def user_or_egotter_requested_job?
    worker_context == CreateUserRequestedPeriodicReportWorker ||
        worker_context == CreateEgotterRequestedPeriodicReportWorker
  end

  def create_new_twitter_user_record
    request = CreateTwitterUserRequest.create(
        requested_by: self.class,
        user_id: user_id,
        uid: user.uid)

    CreateTwitterUserTask.new(request).start!
  rescue CreateTwitterUserRequest::TooShortCreateInterval,
      CreateTwitterUserRequest::NotChanged => e
    logger.info "#{self.class}##{__method__} #{e.inspect} request_id=#{id} create_request_id=#{request&.id}"
  rescue => e
    logger.warn "#{self.class}##{__method__} #{e.inspect} request_id=#{id} create_request_id=#{request&.id}"
  end

  PERIOD_START = 1.day

  def build_report_options
    start_date = PERIOD_START.ago
    end_date = Time.zone.now

    # To specify start_date, UnfriendsBuilder is used
    builder = UnfriendsBuilder.new(user.uid, start_date: start_date, end_date: end_date)
    unfriends = TwitterDB::User.where_and_order_by_field(uids: builder.unfriends.flatten.take(10)).map(&:screen_name)
    unfollowers = TwitterDB::User.where_and_order_by_field(uids: builder.unfollowers.flatten.take(10)).map(&:screen_name)

    first_user = TwitterUser.find_by(id: builder.first_user&.id)
    last_user = TwitterUser.find_by(id: builder.last_user&.id)

    {
        request_id: id,
        start_date: start_date,
        end_date: end_date,
        first_friends_count: first_user&.friends_count,
        first_followers_count: first_user&.followers_count,
        last_friends_count: last_user&.friends_count,
        last_followers_count: last_user&.followers_count,
        unfriends: unfriends,
        unfollowers: unfollowers
    }
  end

  INTERVAL = 1.hour

  class << self
    def interval_too_short?(include_user_id:, reject_id:)
      last_request = CreatePeriodicReportRequest.where(user_id: include_user_id).
          where(status: '').
          where.not(finished_at: nil).
          where.not(id: reject_id).
          order(created_at: :desc).
          first

      if last_request
        last_request.finished_at > INTERVAL.ago
      else
        false
      end
    end
  end
end
