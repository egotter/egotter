# == Schema Information
#
# Table name: search_histories
#
#  id         :integer          not null, primary key
#  session_id :string(191)      default(""), not null
#  user_id    :integer          not null
#  uid        :bigint(8)        not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_search_histories_on_created_at  (created_at)
#  index_search_histories_on_session_id  (session_id)
#  index_search_histories_on_user_id     (user_id)
#

class SearchHistory < ApplicationRecord
  belongs_to :user, optional: true
  has_one :twitter_db_user, primary_key: :uid, foreign_key: :uid, class_name: 'TwitterDB::User'

  validates :user_id, numericality: {only_integer: true}
  validates :session_id, format: {with: /\A.+\w+.+\Z/}

  def to_param
    screen_name
  end

  delegate(
    *%i(
      uid
      screen_name
      name
      friends_count
      followers_count
      statuses_count
      description
      profile_image_url_https
      protected
      verified
      suspended
      inactive
      status
    ),
    to: :twitter_db_user,
    allow_nil: true
  )

  def search_logs(duration: 30.minutes)
    SearchLog.where(created_at: (created_at - duration)..created_at).
        where(session_id: session_id).
        order(created_at: :asc)
  end

  def source
    log = search_logs.select(:path, :referer).first
    return 'log not found' unless log

    if log.referer.blank?
      path_uri = URI.parse(log.path)
      path_query = URI::decode_www_form(path_uri.query.to_s).to_h

      result =
          if path_uri.path.start_with?('/timelines/') && path_query['medium'] == 'dm'
            "dm(#{path_query['type']}, direct)"
          else
            'blank referer'
          end

      return result
    end

    uri = URI.parse(log.referer)
    query = URI::decode_www_form(uri.query.to_s).to_h

    if uri.host == 't.co'
      path_uri = URI.parse(log.path)
      path_query = URI::decode_www_form(path_uri.query.to_s).to_h

      if path_uri.path.start_with?('/timelines/') && path_query['medium'] == 'dm'
        "dm(#{path_query['type']})"
      else
        uri.host
      end
    else
      uri.host
    end
  end
end
