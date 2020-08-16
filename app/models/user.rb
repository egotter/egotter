# == Schema Information
#
# Table name: users
#
#  id               :integer          not null, primary key
#  uid              :bigint(8)        not null
#  screen_name      :string(191)      not null
#  authorized       :boolean          default(TRUE), not null
#  locked           :boolean          default(FALSE), not null
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
  include Concerns::User::Purchases
  include Concerns::TwitterUser::Inflections

  def remember_created_at=(_)
  end

  with_options dependent: :destroy, validate: false, autosave: false do |obj|
    order_by_desc = -> { order(created_at: :desc) }

    obj.has_many :search_reports,         order_by_desc
    obj.has_many :welcome_messages,       order_by_desc
    obj.has_many :follow_requests,        order_by_desc
    obj.has_many :unfollow_requests,      order_by_desc
    obj.has_many :reset_egotter_requests, order_by_desc
    obj.has_many :delete_tweets_requests, order_by_desc
    obj.has_many :reset_cache_requests,   order_by_desc
    obj.has_many :tweet_requests,         order_by_desc

    obj.has_one :notification_setting
    obj.has_one :periodic_report_setting
    obj.has_one :credential_token
    obj.has_many :orders
    obj.has_many :coupons
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

  scope :premium, -> do
    includes(:orders).merge(Order.unexpired)
        .references(:orders)
  end

  class << self
    def egotter
      find_by(uid: EGOTTER_UID)
    end

    def admin
      find_by(uid: ADMIN_UID)
    end

    def update_or_create_with_token!(values)
      user = User.find_or_initialize_by(uid: values.delete(:uid))
      user.assign_attributes(values)

      if user.new_record?
        transaction do
          user.save!
          user.create_notification_setting!(report_interval: NotificationSetting::DEFAULT_REPORT_INTERVAL)
          user.create_periodic_report_setting!
          user.create_credential_token!(token: user.token, secret: user.secret)
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

    def find_by_token(token, secret)
      find_by(token: token, secret: secret)
    end

    def authorized_ids(reload = false)
      cache = ActiveSupport::Cache::RedisCacheStore.new(
          namespace: "#{Rails.env}:#{__method__}",
          expires_in: 20.minutes,
          race_condition_ttl: 3.minutes,
          redis: Redis.client
      )
      key = 'user_ids'

      if !reload && cache.exist?(key)
        JSON.parse(cache.read(key))
      else
        @mutex ||= Mutex.new
        user_ids = nil
        @mutex.synchronize {
          user_ids = authorized.order(created_at: :desc).limit(100).pluck(:id)
          cache.write('user_ids', user_ids.to_json)
        }
        user_ids
      end
    rescue => e
      logger.warn "#{__method__} #{e.inspect} reload=#{reload}"
      authorized.order(created_at: :desc).limit(100).pluck(:id)
    end

    def pick_authorized_id(candidate_ids = nil)
      candidate_ids = authorized_ids if candidate_ids.nil?
      user = nil

      10.times do
        begin
          user = User.find(candidate_ids.sample)
          user.api_client.twitter.verify_credentials
          user.api_client.twitter.users([user.uid, user.id])
        rescue => e
          user = nil
        else
          break
        end
      end

      user&.id
    end
  end

  def to_param
    screen_name
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
    tweet_requests.where(created_at: SHARE_EGOTTER_DURATION.hour.ago..Time.zone.now).
        where(deleted_at: nil).size
  end
  alias sharing_count sharing_egotter_count

  def valid_coupons_search_count
    coupons.where('expires_at > ?', Time.zone.now).sum(:search_count)
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

  def add_atmark_to_periodic_report?
    has_valid_subscription? || 1.weeks.ago < created_at
  end
end
