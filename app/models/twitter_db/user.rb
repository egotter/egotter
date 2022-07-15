# == Schema Information
#
# Table name: twitter_db_users
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
#  geo_enabled             :boolean          default(FALSE), not null
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
#  index_twitter_db_users_on_created_at   (created_at)
#  index_twitter_db_users_on_screen_name  (screen_name)
#  index_twitter_db_users_on_uid          (uid) UNIQUE
#  index_twitter_db_users_on_updated_at   (updated_at)
#

module TwitterDB
  class User < ApplicationRecord

    validates_with Validations::UidValidator
    validates_with Validations::ScreenNameValidator

    attr_accessor :account_status

    def protected?
      self.protected
    end

    def status_interval_avg
      TwitterUser.latest_by(uid: uid)&.status_interval_avg
    end

    def follow_back_rate
      TwitterUser.latest_by(uid: uid)&.follow_back_rate
    end

    def reverse_follow_back_rate
      TwitterUser.latest_by(uid: uid)&.reverse_follow_back_rate
    end

    def to_param
      screen_name
    end

    INACTIVE_INTERVAL = 2.weeks

    class << self
      def inactive_user
        where.not(status_created_at: nil).where('status_created_at < ?', INACTIVE_INTERVAL.ago)
      end

      def import_by!(users:)
        built_users = users.map { |user| build_by(user: user) }
        built_users.sort_by!(&:uid)

        columns = column_names.reject { |name| %w(id created_at updated_at).include?(name) }
        values = built_users.map { |user| user.slice(*columns).values }

        import columns, values, on_duplicate_key_update: columns, batch_size: 500, validate: false
      end
    end

    module QueryMethods
      extend ActiveSupport::Concern

      class_methods do
        # TODO Set user_id
        # This method makes the result unique.
        def where_and_order_by_field(uids:, inactive: nil, slice_count: 1000, thread: true)
          caller_name = (caller[0][/`([^']*)'/, 1] rescue '')

          if thread && uids.size > slice_count
            # TODO Experimental
            result = Queue.new
            Parallel.each_with_index(uids.uniq.each_slice(slice_count), in_threads: 2) do |uids_array, i|
              result << [i, where_and_order_by_field_each_slice(uids_array, inactive, caller_name)]
            end
            result.size.times.map { result.pop }.sort_by { |i, _| i }.map(&:second).flatten
          else
            uids.uniq.each_slice(slice_count).map do |uids_array|
              where_and_order_by_field_each_slice(uids_array, inactive, caller_name)
            end.flatten
          end
        rescue ThreadError => e
          if thread
            Airbag.warn "#where_and_order_by_field: ThreadError is detected and retry without threads exception=#{e.inspect}"
            thread = false
            retry
          else
            raise
          end
        end

        private

        def where_and_order_by_field_each_slice(uids, inactive, caller_name = nil)
          Rails.logger.silence do
            records = where(uid: uids)
            records = records.inactive_user if !inactive.nil? && inactive
            records.order_by_field(uids).to_a
          end
        end
      end

      included do
        scope :order_by_field, -> (uids) { order(Arel.sql("field(uid, #{uids.join(',')})")) }
      end
    end
    include QueryMethods

    module Builder
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
    end
    include Builder
  end
end
