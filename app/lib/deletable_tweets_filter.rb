class DeletableTweetsFilter

  DATE_REGEXP = /\A\d{4}-\d{2}-\d{2}\z/
  MAX_TWEET_TEXT = 20

  def initialize(attrs)
    @retweet_count = to_integer(attrs[:retweet_count])
    @favorite_count = to_integer(attrs[:favorite_count])
    @since_date = Time.zone.parse(attrs[:since_date]) if attrs[:since_date]&.match?(DATE_REGEXP)
    @until_date = Time.zone.parse(attrs[:until_date]) if attrs[:until_date]&.match?(DATE_REGEXP)
    @hashtags = to_bool(attrs[:hashtags])
    @user_mentions = to_bool(attrs[:user_mentions])
    @urls = to_bool(attrs[:urls])
    @media = to_bool(attrs[:media])
    @tweet_text = attrs[:tweet_text]
    @deleted = to_bool(attrs[:deleted])
  end

  def apply(query)
    if @retweet_count.present?
      query = query.where('retweet_count >= ?', @retweet_count)
    end

    if @favorite_count.present?
      query = query.where('favorite_count >= ?', @favorite_count)
    end

    if @since_date.present?
      query = query.where('tweeted_at >= ?', @since_date)
    end

    if @until_date.present?
      query = query.where('tweeted_at <= ?', @until_date)
    end

    unless @hashtags.nil?
      if @hashtags
        query = query.where('json_length(hashtags) > 0')
      else
        query = query.where('json_length(hashtags) = 0')
      end
    end

    unless @user_mentions.nil?
      if @user_mentions
        query = query.where('json_length(user_mentions) > 0')
      else
        query = query.where('json_length(user_mentions) = 0')
      end
    end

    unless @urls.nil?
      if @urls
        query = query.where('json_length(urls) > 0')
      else
        query = query.where('json_length(urls) = 0')
      end
    end

    unless @media.nil?
      if @media
        query = query.where('json_length(media) > 0')
      else
        query = query.where('json_length(media) = 0')
      end
    end

    if @tweet_text.present? && @tweet_text.length < MAX_TWEET_TEXT
      query = query.where('properties->>"$.text" like ?', "%#{DeletableTweet.sanitize_sql_like(@tweet_text)}%")
    end

    if @deleted
      query = query.where.not(deleted_at: nil)
    else
      query = query.where(deleted_at: nil)
    end

    query
  end

  def to_hash
    {
        retweet_count: @retweet_count,
        favorite_count: @favorite_count,
        since_date: @since_date,
        until_date: @until_date,
        hashtags: @hashtags,
        user_mentions: @user_mentions,
        urls: @urls,
        media: @media,
        deleted: @deleted,
    }
  end

  private

  def to_integer(val)
    case val
    when '1', '10', '100'
      val.to_i
    else
      nil
    end
  end

  def to_bool(val)
    case val
    when 'true'
      true
    when 'false'
      false
    else
      nil
    end
  end

  class << self
    def from_hash(hash)
      new(
          retweet_count: hash[:retweet_count],
          favorite_count: hash[:favorite_count],
          since_date: hash[:since_date],
          until_date: hash[:until_date],
          hashtags: hash[:hashtags],
          user_mentions: hash[:user_mentions],
          urls: hash[:urls],
          media: hash[:media],
          tweet_text: hash[:tweet_text],
          deleted: hash[:deleted],
      )
    end
  end
end

