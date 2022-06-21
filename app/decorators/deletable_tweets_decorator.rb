class DeletableTweetsDecorator
  include TwitterHelper

  def initialize(records, user)
    @records = records
    @user = user
  end

  def to_json
    @records.map.with_index do |record, i|
      {
          id: record.tweet_id.to_s,
          text: strip_tags(record.properties['text']).gsub("\n", '<br>'),
          retweet_count: record.retweet_count,
          favorite_count: record.favorite_count,
          media: record.media&.map { |m| {url: m['media_url_https']} },
          url: tweet_url(@user.screen_name, record.tweet_id),
          deletion_reserved: record.deleted_at.nil? && !record.deletion_reserved_at.nil?,
          deletion_reserved_label: '削除予約済み',
          deleted: !record.deleted_at.nil?,
          deleted_label: '削除済み',
          created_at: I18n.l(record.tweeted_at.in_time_zone('Tokyo'), format: :deletable_tweets_long),
          index: i + 1,
      }
    end
  end

  private

  def strip_tags(html)
    ApplicationController.helpers.strip_tags(html)
  end
end
