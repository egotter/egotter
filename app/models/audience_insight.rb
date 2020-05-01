# == Schema Information
#
# Table name: audience_insights
#
#  id                     :bigint(8)        not null, primary key
#  uid                    :bigint(8)        not null
#  categories_text        :text(65535)      not null
#  friends_text           :text(65535)      not null
#  followers_text         :text(65535)      not null
#  new_friends_text       :text(65535)      not null
#  new_followers_text     :text(65535)      not null
#  unfriends_text         :text(65535)      not null
#  unfollowers_text       :text(65535)      not null
#  new_unfriends_text     :text(65535)      not null
#  new_unfollowers_text   :text(65535)      not null
#  tweets_categories_text :text(65535)      not null
#  tweets_text            :text(65535)      not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_audience_insights_on_created_at  (created_at)
#  index_audience_insights_on_uid         (uid) UNIQUE
#

class AudienceInsight < ApplicationRecord

  validates :uid, presence: true, uniqueness: true

  before_validation do
    %i(
      unfriends_text
      unfollowers_text
      new_unfriends_text
      new_unfollowers_text
      tweets_categories_text
      tweets_text
    ).each do |key|
      self[key] = '' if self[key].blank?
    end
  end

  # unfriends, unfollowers, new_unfriends, new_unfollowers, tweets_categories and tweets are ignored
  CHART_NAMES = %w(
    categories
    friends
    followers
    new_friends
    new_followers
  )

  CHART_NAMES.each do |chart_name|
    define_method(chart_name) do
      ivar_name = "@#{chart_name}"

      if instance_variable_defined?(ivar_name)
        instance_variable_get(ivar_name)
      else
        text = send("#{chart_name}_text")
        if text.present?
          instance_variable_set(ivar_name, JSON.parse(text, symbolize_names: true))
        else
          nil
        end
      end
    end
  end

  def fresh?
    if new_record?
      false
    else
      ttl = Rails.env.production? ? 30.minutes : 1.minutes
      Time.zone.now - updated_at < ttl
    end
  end
end
