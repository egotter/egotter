class SearchCountLimitation
  extend Memoization

  SIGN_IN_BONUS = Rails.configuration.x.constants[:search_count_limitation][:sign_in_bonus]
  SHARING_BONUS = Rails.configuration.x.constants[:search_count_limitation][:sharing_bonus]
  PERIODIC_TWEET_BONUS = Rails.configuration.x.constants[:search_count_limitation][:periodic_tweet_bonus]
  PERIODIC_TWEET_MIN = Rails.configuration.x.constants[:search_count_limitation][:periodic_tweet_min]
  PERIODIC_TWEET_MAX = Rails.configuration.x.constants[:search_count_limitation][:periodic_tweet_max]
  CONTINUOUS_SIGN_IN_BONUS = Rails.configuration.x.constants[:search_count_limitation][:continuous_sign_in_bonus]
  ANONYMOUS = Rails.configuration.x.constants[:search_count_limitation][:anonymous]
  BASIC_PLAN = Rails.configuration.x.constants[:search_count_limitation][:basic_plan]

  SEARCH_COUNT_PERIOD = 1.day.to_i

  def initialize(user:, session_id:)
    @user = user
    @session_id = session_id
  end

  def max_count
    count = ANONYMOUS

    if @user
      count += SIGN_IN_BONUS
    end

    if @user&.has_valid_subscription?
      count = @user.purchased_search_count
    end

    if @user && @user.sharing_count > 0
      count += @user.sharing_count * current_sharing_bonus
    end

    if @user
      count += @user.coupons_search_count
    end

    if @user && CreatePeriodicTweetRequest.exists?(user_id: @user.id)
      count += PERIODIC_TWEET_BONUS
    end

    if @user && @user.continuous_sign_in?
      count += CONTINUOUS_SIGN_IN_BONUS
    end

    count
  end
  memoize

  def remaining_count
    [0, max_count - current_count].max
  rescue => e
    Airbag.warn "##{__method__} Maybe invalid session_id class=#{@session_id.class} inspect=#{@session_id.inspect}"
    raise
  end
  memoize

  def count_remaining?
    remaining_count >= 1
  end
  memoize

  def current_count
    # The cause of "ActionView::Template::Error (can't quote Hash)" is invalid session_id.
    # e.g. {"public_id"=>"hash string"}
    SearchHistory.where(where_condition).size
  end
  memoize

  def count_reset_in
    record = SearchHistory.order(created_at: :asc).find_by(where_condition)
    record ? [0, (record.created_at + SEARCH_COUNT_PERIOD.seconds - Time.zone.now).to_i].max : 0
  end
  memoize

  def current_sharing_bonus
    if @user&.authorized?
      followers = TwitterUser.latest_by(uid: @user.uid)&.followers_count
      followers = TwitterDB::User.find_by(uid: @user.uid)&.followers_count unless followers
      followers = 0 unless followers
    else
      followers = 0
    end

    case followers
    when 0..1000 then SHARING_BONUS
    when 1001..2000 then SHARING_BONUS + 1
    when 2001..5000 then SHARING_BONUS + 2
    else SHARING_BONUS + 3
    end
  end
  memoize

  def to_h
    {
        user_id: @user&.id,
        max: max_count,
        remaining: remaining_count,
        current: current_count,
        sharing_bonus: current_sharing_bonus,
        sharing_count: @user&.sharing_count,
    }
  end

  private

  def where_condition
    condition =
        if @user
          {user_id: @user.id}
        elsif @session_id
          {session_id: @session_id}
        else
          raise
        end
    condition.merge(created_at: SEARCH_COUNT_PERIOD.seconds.ago..Time.zone.now)
  end
end
