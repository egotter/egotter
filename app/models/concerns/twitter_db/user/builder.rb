require 'active_support/concern'

module Concerns::TwitterDB::User::Builder
  extend ActiveSupport::Concern

  class_methods do
    def build_by(user:)
      if user[:screen_name] == 'suspended'
        return new(uid: user[:id], screen_name: user[:screen_name])
      end

      user[:account_created_at] = user[:created_at]
      user[:status_created_at] = user[:status] ? user[:status][:created_at] : nil

      if user[:description]
        begin
          user[:entities][:description][:urls].each do |entity|
            user[:description].gsub!(entity[:url], entity[:expanded_url])
          end
        rescue => e
        end

        if user[:description].length >= 180
          user[:description] = user[:description].truncate(180)
        end

        user[:description] = user[:description]
      end

      if user[:url]
        begin
          user[:url] = user[:entities][:url][:urls][0][:expanded_url]
        rescue => e
        end
      end

      %i(url profile_image_url_https profile_banner_url).each do |key|
        user[key] = '' if !user.has_key?(key) || user[key].nil?

        if user[key].to_s.length >= 180
          user[key] = ''
        end
      end

      new(
          uid:                     user[:id],
          screen_name:             user[:screen_name],
          friends_count:           user[:friends_count],
          followers_count:         user[:followers_count],
          protected:               user[:protected] || false,
          suspended:               user[:suspended] || false,
          status_created_at:       user[:status_created_at],
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

  included do
  end
end
