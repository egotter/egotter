# == Schema Information
#
# Table name: users
#
#  id               :integer          not null, primary key
#  uid              :bigint(8)        not null
#  screen_name      :string(191)      not null
#  authorized       :boolean          default(TRUE), not null
#  token            :string(191)      not null
#  secret           :string(191)      not null
#  email            :string(191)      default(""), not null
#  first_access_at  :datetime
#  last_access_at   :datetime
#  first_search_at  :datetime
#  last_search_at   :datetime
#  first_sign_in_at :datetime
#  last_sign_in_at  :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_users_on_created_at       (created_at)
#  index_users_on_first_access_at  (first_access_at)
#  index_users_on_last_access_at   (last_access_at)
#  index_users_on_screen_name      (screen_name)
#  index_users_on_token            (token)
#  index_users_on_uid              (uid) UNIQUE
#

class User < ApplicationRecord
  devise :rememberable, :omniauthable

  has_many :visits, class_name: 'Ahoy::Visit'

  include Concerns::User::ApiAccess
  include Concerns::TwitterUser::Inflections
  include Concerns::Visitor::Activeness

  def remember_created_at=(_)
  end

  with_options dependent: :destroy, validate: false, autosave: false do |obj|
    order_by_desc = -> { order(created_at: :desc) }

    obj.has_many :prompt_reports,                order_by_desc
    obj.has_many :search_reports,                order_by_desc
    obj.has_many :news_reports,                  order_by_desc
    obj.has_many :welcome_messages,              order_by_desc
    obj.has_many :create_prompt_report_requests, order_by_desc
    obj.has_many :create_prompt_report_logs,     order_by_desc
    obj.has_many :create_test_report_requests,   order_by_desc
    obj.has_many :follow_requests,               order_by_desc
    obj.has_many :unfollow_requests,             order_by_desc
    obj.has_many :reset_egotter_requests,        order_by_desc
    obj.has_many :delete_tweets_requests,        order_by_desc
    obj.has_many :reset_cache_requests,          order_by_desc
    obj.has_many :tweet_requests,                order_by_desc

    obj.has_one :notification_setting
    obj.has_many :orders
    obj.has_many :access_days
  end

  accepts_nested_attributes_for :notification_setting

  validates :uid, presence: true, uniqueness: true
  validates_with Validations::UidValidator
  validates :screen_name, presence: true
  validates_with Validations::ScreenNameValidator
  validates :secret, presence: true
  validates :token, presence: true
  validates_with Validations::EmailValidator

  scope :authorized, -> { where(authorized: true) }
  scope :can_send_dm, -> do
    includes(:notification_setting)
      .where('notification_settings.dm = ?', true)
      .where('last_dm_at IS NULL OR last_dm_at < ?', NotificationSetting::DM_INTERVAL.ago)
      .references(:notification_settings)
  end
  scope :can_send_news, -> do
    includes(:notification_setting)
      .where('notification_settings.news = ?', true)
      .where('last_dm_at IS NULL OR last_news_at < ?', NotificationSetting::NEWS_INTERVAL.ago)
      .references(:notification_settings)
  end

  scope :enough_permission_level, -> do
    includes(:notification_setting)
        .where("notification_settings.permission_level = '#{NotificationSetting::PROPER_PERMISSION}'")
        .references(:notification_settings)
  end
  scope :prompt_report_enabled, -> do
    includes(:notification_setting)
        .where('notification_settings.dm = TRUE')
        .references(:notification_settings)
  end
  scope :prompt_report_interval_ok, -> do
    includes(:notification_setting)
        .where('last_dm_at IS NULL OR last_dm_at < NOW() - INTERVAL notification_settings.report_interval SECOND')
        .references(:notification_settings)
  end

  class << self
    def egotter
      find_by(uid: User::EGOTTER_UID)
    end

    def update_or_create_with_token!(values)
      user = User.find_or_initialize_by(uid: values.delete(:uid))
      user.assign_attributes(values)

      if user.new_record?
        transaction do
          user.save!
          user.create_notification_setting!(report_interval: NotificationSetting::DEFAULT_REPORT_INTERVAL)
        end
        yield(user, :create) if block_given?
      else
        user.save! if user.changed?
        yield(user, :update) if block_given?
      end

      user
    rescue => e
      logger.warn "#{self}##{__method__}: #{e.class} #{e.message} #{e.respond_to?(:record) ? e.record.inspect : 'NONE'} #{values.inspect}"
      raise e
    end
  end

  def twitter_user
    logger.info "Deprecated calling User#twitter_user #{(caller[0][/`([^']*)'/, 1] rescue '')}"
    if instance_variable_defined?(:@twitter_user)
      @twitter_user
    else
      @twitter_user = TwitterUser.latest_by(uid: uid)
    end
  end

  # TODO Remove later
  def unauthorized?
    !authorized?
  end

  def current_friend_uids
    if instance_variable_defined?(:@current_friend_uids)
      @current_friend_uids
    else
      twitter_user = TwitterUser.latest_by(uid: uid)
      uids = Set.new(twitter_user&.friend_uids || [])

      requests = following_requests(twitter_user&.created_at) + unfollowing_requests(twitter_user&.created_at)
      requests.sort_by!(&:created_at)

      requests.each do |req|
        if req.class == FollowRequest
          uids.add(req.uid)
        elsif req.class == UnfollowRequest
          uids.subtract([req.uid])
        else
          logger.warn "#{__method__} Invalid #{req.inspect}"
        end
      end

      @current_friend_uids = uids.to_a
    end
  rescue => e
    logger.warn "#{__method__} #{e.class} #{e.message}"
    []
  end

  def following_requests(created_at)
    created_at = 1.day.ago unless created_at
    FollowRequest.temporarily_following(user_id: id, created_at: created_at)
  end

  def unfollowing_requests(created_at)
    created_at = 1.day.ago unless created_at
    UnfollowRequest.temporarily_unfollowing(user_id: id, created_at: created_at)
  end

  def is_following?(uid)
    current_friend_uids.include?(uid.to_i)
  end

  def following_egotter?
    EgotterFollower.exists?(uid: uid)
  end

  SHARE_EGOTTER_DURATION = 1

  def sharing_egotter_count
    tweet_requests.where(created_at: SHARE_EGOTTER_DURATION.hour.ago..Time.zone.now).size
  end

  def search_mode
    if following_egotter?
      ActiveSupport::StringInquirer.new('fast')
    else
      ActiveSupport::StringInquirer.new('slow')
    end
  end

  ADMIN_UID = 58135830
  EGOTTER_UID = 187385226

  def admin?
    uid == ADMIN_UID
  end

  def has_valid_subscription?
    orders.unexpired.any?
  end

  def purchased_plan_name
    orders.unexpired.last.name
  end

  def purchased_search_count
    orders.unexpired.last.search_count
  end

  def latest_prompt_report
    prompt_reports.reorder(created_at: :desc).first
  end

  include Concerns::LastSessionAnalytics

  def last_session_duration
    period_end = last_access_at || created_at
    (period_end - 30.minutes)..period_end
  end
end
