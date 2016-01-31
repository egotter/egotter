# == Schema Information
#
# Table name: statuses
#
#  id          :integer          not null, primary key
#  uid         :string(191)      not null
#  screen_name :string(191)      not null
#  status_info :text(65535)      not null
#  from_id     :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_statuses_on_from_id      (from_id)
#  index_statuses_on_screen_name  (screen_name)
#  index_statuses_on_uid          (uid)
#

class Status < ActiveRecord::Base
  belongs_to :twitter_user

  STATUS_SAVE_KEYS = %i(
    created_at
    id
    text
    source
    truncated
    in_reply_to_status_id
    in_reply_to_status_id_str
    in_reply_to_user_id
    in_reply_to_user_id_str
    in_reply_to_screen_name
    geo
    coordinates
    place
    contributors
    is_quote_status
    retweet_count
    favorite_count
    favorited
    retweeted
    possibly_sensitive
    lang
  )

  delegate *STATUS_SAVE_KEYS.reject { |k| k.in?(%i(id screen_name)) }, to: :status_info_mash

  def status_info_mash
    @status_info_mash ||= Hashie::Mash.new(JSON.parse(status_info))
  end

  def has_key?(key)
    status_info_mash.has_key?(key)
  end

  with_options on: :create do |obj|
    obj.validates :uid, presence: true, numericality: :only_integer
    obj.validates :screen_name, format: {with: /\A[a-zA-Z0-9_]{1,20}\z/}
    obj.validates :user_info, presence: true
  end
end
