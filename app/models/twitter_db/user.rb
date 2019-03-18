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

    delegate :name, :location, :description, :url, :protected, :followers_count, :friends_count, :verified, :statuses_count, :account_created_at, :profile_image_url_https, :profile_banner_url, :profile_link_color, :suspended, to: :profile, allow_nil: true

    def inactive?
      profile&.status_created_at && profile.status_created_at < 2.weeks.ago
    end

    # Used in view
    def inactive
      inactive?
    end

    def to_param
      screen_name
    end
  end
end
