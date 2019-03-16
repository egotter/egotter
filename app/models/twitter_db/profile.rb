# == Schema Information
#
# Table name: twitter_db_profiles
#
#  id                      :bigint(8)        not null, primary key
#  uid                     :bigint(8)        not null
#  screen_name             :string(191)      default(""), not null
#  friends_count           :integer          default(-1), not null
#  followers_count         :integer          default(-1), not null
#  protected               :boolean          default(FALSE), not null
#  suspended               :boolean          default(FALSE), not null
#  status_created_at       :datetime
#  account_created_at      :datetime
#  statuses_count          :integer          default(-1), not null
#  favourites_count        :integer          default(-1), not null
#  listed_count            :integer          default(-1), not null
#  name                    :string(191)      default(""), not null
#  location                :string(191)      default(""), not null
#  description             :string(191)      default(""), not null
#  url                     :string(191)      default(""), not null
#  geo_enabled             :string(191)      default("0"), not null
#  verified                :boolean          default(FALSE), not null
#  lang                    :string(191)      default(""), not null
#  profile_image_url_https :string(191)      default(""), not null
#  profile_banner_url      :string(191)      default(""), not null
#  profile_link_color      :string(191)      default(""), not null
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#
# Indexes
#
#  index_twitter_db_profiles_on_created_at   (created_at)
#  index_twitter_db_profiles_on_screen_name  (screen_name)
#  index_twitter_db_profiles_on_uid          (uid) UNIQUE
#

module TwitterDB
  class Profile < ApplicationRecord
    with_options(primary_key: :uid, foreign_key: :uid, class_name: 'TwitterDB::User') do |obj|
      obj.belongs_to :user
    end


    class << self
      def build_by(user:)
        if user[:screen_name] == 'suspended'
          new(uid: user.uid, screen_name: user.screen_name)
        else
          if user.is_a?(TwitterDB::User)
            values = {
                account_created_at: user.account_created_at,
                status_created_at: (user.status&.created_at)
            }
            user = user.attributes.merge(user._user_info.to_h).merge(values)
            user = user.symbolize_keys
          end

          if user[:description].to_s.length >= 180
            user[:description] = user[:description].truncate(180)
          end

          user[:description] = user[:description].gsub(/\R/, ' ')

          %i(url profile_image_url_https profile_banner_url).each do |key|
            user[key] = '' if !user.has_key?(key) || user[key].nil?

            if user[key].to_s.length >= 180
              user[key] = ''
            end
          end

          new(
              uid:                     user[:uid],
              screen_name:             user[:screen_name],
              friends_count:           user[:friends_count],
              followers_count:         user[:followers_count],
              protected:               user[:protected] || false,
              suspended:               user[:suspended] || false,
              status_created_at:       (user[:status][:created_at] rescue nil),
              account_created_at:      user[:account_created_at],
              statuses_count:          user[:statuses_count],
              favourites_count:        user[:favourites_count],
              listed_count:            user[:listed_count],
              name:                    user[:name],
              location:                user[:location] || '',
              description:             user[:description] || '',
              url:                     user[:url] || '',
              geo_enabled:             user[:geo_enabled] || false,
              verified:                user[:verified] || false,
              lang:                    user[:lang] || '',
              profile_image_url_https: user[:profile_image_url_https] || '',
              profile_banner_url:      user[:profile_banner_url] || '',
              profile_link_color:      user[:profile_link_color] || '',
              )
        end
      end
    end
  end
end
