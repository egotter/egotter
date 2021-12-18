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

# TODO Remove later
class AudienceInsight < ApplicationRecord
end
