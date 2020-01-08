# == Schema Information
#
# Table name: create_twitter_user_requests
#
#  id              :bigint(8)        not null, primary key
#  session_id      :string(191)
#  user_id         :integer          not null
#  uid             :bigint(8)        not null
#  twitter_user_id :integer
#  requested_by    :string(191)      default(""), not null
#  finished_at     :datetime
#  ahoy_visit_id   :bigint(8)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_create_twitter_user_requests_on_created_at       (created_at)
#  index_create_twitter_user_requests_on_twitter_user_id  (twitter_user_id)
#  index_create_twitter_user_requests_on_user_id          (user_id)
#

class CreateTwitterUserRequest < ApplicationRecord
  include Concerns::Request::Runnable
  belongs_to :user, optional: true
  belongs_to :twitter_user, optional: true

  validates :user_id, presence: true
  validates :uid, presence: true

  # context:
  #   :prompt_report
  def perform!(context = nil)
    perform_validation!(context)

    @snapshot.build_by(@resources)
    twitter_user = @snapshot.twitter_user
    twitter_user.user_id = user_id

    if twitter_user.save
      update(twitter_user_id: twitter_user.id)
      twitter_user
    else
      raise RecordInvalid.new(twitter_user)
    end
  end

  def perform_validation!(context)
    raise Unauthorized if user&.unauthorized?
    raise TooShortCreateInterval if TwitterUser.too_short_creation_interval?(uid: uid)
    raise TooManyFriends.new('Already exists') if search_limited_and_already_persisted?

    @snapshot = TwitterUserSnapshot.initialize_by(user: fetch_user)

    begin
      @resources = dispatch_resources_fetcher(context).fetch
    rescue Error => e
      raise
    rescue Twitter::Error::TooManyRequests => e
      raise
    rescue => e
      if ServiceStatus.connection_reset_by_peer?(e)
        retry
      else
        raise dispatch_exception(e)
      end
    end

    @snapshot.build_friends(@resources[:friend_ids]).
        build_followers(@resources[:follower_ids])

    unless TwitterUser.exists?(uid: uid)
      return true
    end

    if TwitterUser.friendships_changed?(uid, @snapshot)
      true
    else
      raise NotChanged.new('Before build')
    end
  end

  def dispatch_exception(ex)
    if AccountStatus.unauthorized?(ex)
      Unauthorized
    elsif AccountStatus.protected?(ex)
      Protected
    elsif AccountStatus.blocked?(ex)
      Blocked
    elsif AccountStatus.temporarily_locked?(ex)
      Forbidden
    elsif ServiceStatus.service_unavailable?(ex)
      ServiceUnavailable
    elsif ServiceStatus.internal_server_error?(ex)
      InternalServerError
    else
      Unknown.new("#{__method__} #{ex.class} #{ex.message}")
    end
  end

  def search_limited_and_already_persisted?
    SearchLimitation.limited?(fetch_user, signed_in: user) && TwitterUser.exists?(uid: uid)
  end

  def fetch_user
    @fetch_user ||= client.user(uid)
  rescue => e
    if AccountStatus.unauthorized?(e)
      raise Unauthorized
    else
      raise Unknown.new("#{__method__} #{e.class} #{e.message}")
    end
  end

  def dispatch_resources_fetcher(context)
    fetcher_class =
        if context == :prompt_report
          TwitterUserFetcher::PromptReportFetcher
        else
          case [search_oneself?, SearchLimitation.limited?(fetch_user, signed_in: user)]
          when [true, true] then TwitterUserFetcher::SearchOneselfWithoutFriendshipsFetcher
          when [true, false] then TwitterUserFetcher::SearchOneselfFetcher
          when [false, true] then TwitterUserFetcher::SearchSomeoneWithoutFriendshipsFetcher
          when [false, false] then TwitterUserFetcher::SearchSomeoneFetcher
          end
        end

    fetcher_class.new(client, uid, fetch_user[:screen_name])
  end

  def search_oneself?
    user && user.uid == uid
  end

  def client
    @client ||= (!@user.nil? ? @user.api_client : Bot.api_client)
  end

  def benchmark(message, twitter_user = nil, &block)
    ApplicationRecord.benchmark("Benchmark CreateTwitterUserRequest #{user_id} #{uid} #{message} friends=#{twitter_user&.friends_count} followers=#{twitter_user&.followers_count}", level: :info, &block)
  end

  class Error < StandardError
  end

  class Unauthorized < Error
  end

  class Forbidden < Error
  end

  class Protected < Error
  end

  class Blocked < Error
  end

  class TooShortCreateInterval < Error
  end

  class TooManyFriends < Error
  end

  class RecordInvalid < Error
    def initialize(record)
      super(record.errors.full_messages.join(', '))
    end
  end

  class NotChanged < Error
  end

  class TooManyRequests < Error
  end

  class ServiceUnavailable < Error
  end

  class InternalServerError < Error
  end

  class Unknown < StandardError
  end
end
