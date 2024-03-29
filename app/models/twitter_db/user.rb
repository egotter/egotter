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
#  index_twitter_db_users_on_created_at                 (created_at)
#  index_twitter_db_users_on_screen_name                (screen_name)
#  index_twitter_db_users_on_uid                        (uid) UNIQUE
#  index_twitter_db_users_on_uid_and_status_created_at  (uid,status_created_at)
#  index_twitter_db_users_on_updated_at                 (updated_at)
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

    class << self
      def import_data(data, batch_size: 20)
        users = data.map { |user| build_by(user: user) }
        users.sort_by!(&:uid)

        columns = column_names.reject { |name| %w(id created_at updated_at).include?(name) }
        values = users.map { |user| user.slice(*columns).values }

        import columns, values, on_duplicate_key_update: columns, batch_size: batch_size, validate: false
      end

      # TODO Remove later
      def import_by!(users:, batch_size: 20)
        built_users = users.map { |user| build_by(user: user) }
        built_users.sort_by!(&:uid)

        columns = column_names.reject { |name| %w(id created_at updated_at).include?(name) }
        values = built_users.map { |user| user.slice(*columns).values }

        import columns, values, on_duplicate_key_update: columns, batch_size: batch_size, validate: false
      end

      def persisted_uids_count(uids)
        where(uid: uids).annotate('In #persisted_uids_count').size
      end
    end

    scope :order_by_field, -> (uids) { order(Arel.sql("field(uid, #{uids.join(',')})")) }

    scope :active_period, -> (time) { where('status_created_at is null OR status_created_at > ?', time) }
    scope :active_2weeks, -> { active_period(2.weeks.ago) }

    scope :inactive_period, -> (time) { where('status_created_at < ?', time) }
    scope :inactive_2weeks, -> { inactive_period(2.weeks.ago) }
    scope :inactive_1month, -> { inactive_period(1.month.ago) }
    scope :inactive_3months, -> { inactive_period(3.months.ago) }
    scope :inactive_6months, -> { inactive_period(6.months.ago) }
    scope :inactive_1year, -> { inactive_period(1.year.ago) }

    scope :protected_account, -> { where(protected: true) }
    scope :verified_account, -> { where(verified: true) }
    scope :has_more_friends, -> { where('friends_count > followers_count') }
    scope :has_more_followers, -> { where('followers_count > friends_count') }

    scope :investor, -> { where('description regexp ?', TwitterUserDecorator::INVESTOR_STR) }
    scope :engineer, -> { where('description regexp ?', TwitterUserDecorator::ENGINEER_STR) }
    scope :designer, -> { where('description regexp ?', TwitterUserDecorator::DESIGNER_STR) }
    scope :bikini_model, -> { where('description regexp ?', TwitterUserDecorator::BIKINIMODEL_STR) }
    scope :fashion_model, -> { where('description regexp ?', TwitterUserDecorator::FASHION_MODEL_STR) }
    scope :pop_idol, -> { where('description regexp ?', TwitterUserDecorator::POP_IDOL_STR) }
    scope :too_emotional, -> { where('description regexp ?', TwitterUserDecorator::TOO_EMOTIONAL_STR) }

    scope :has_instagram, -> { where('description regexp "instagram\.com" OR url regexp "instagram\.com"') }
    scope :has_tiktok, -> { where('description regexp "tiktok\.com" OR url regexp "tiktok\.com"') }
    scope :secret_account, -> { where('description regexp ?', TwitterUserDecorator::SECRET_ACCOUNT_STR) }
    scope :adult_account, -> { where('description regexp ?', TwitterUserDecorator::ADULT_ACCOUNT_STR) }

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
