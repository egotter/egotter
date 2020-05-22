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
    include Concerns::TwitterUser::Inflections
    include Concerns::TwitterDB::User::Associations
    include Concerns::TwitterDB::User::Builder

    include Concerns::TwitterDB::User::Batch
    include Concerns::TwitterDB::User::Debug

    validates_with Validations::UidValidator
    validates_with Validations::ScreenNameValidator

    def inactive?
      status_created_at && status_created_at < INACTIVE_INTERVAL.ago
    end

    def active?
      !inactive?
    end

    def protected?
      self.protected
    end

    def follow_back_rate
      TwitterUser.latest_by(uid: uid)&.follow_back_rate
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
  end
end
