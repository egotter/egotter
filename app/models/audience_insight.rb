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

  CHART_NAMES =
      column_names.reject {|name| %w(id uid created_at updated_at).include?(name)}.map do |column_name|
        column_name.delete_suffix('_text')
      end

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
      seconds = Rails.env.production? ? 30.minutes : 1.minutes
      Time.zone.now - updated_at < seconds
    end
  end
end
