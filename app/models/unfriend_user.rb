# == Schema Information
#
# Table name: unfriend_users
#
#  id                 :bigint(8)        not null, primary key
#  from_uid           :bigint(8)        not null
#  sort_order         :integer          not null
#  account_status     :string(191)
#  uid                :bigint(8)        not null
#  screen_name        :string(191)      not null
#  friends_count      :integer          not null
#  followers_count    :integer          not null
#  protected          :boolean          not null
#  suspended          :boolean          not null
#  status_created_at  :datetime
#  account_created_at :datetime
#  statuses_count     :integer          not null
#  favourites_count   :integer          not null
#  listed_count       :integer          not null
#  name               :string(191)      not null
#  location           :string(191)      not null
#  description        :text(65535)
#  url                :string(191)      not null
#  verified           :boolean          not null
#  profile_image_url  :string(191)      not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_unfriend_users_on_created_at               (created_at)
#  index_unfriend_users_on_from_uid_and_sort_order  (from_uid,sort_order) UNIQUE
#
class UnfriendUser < ApplicationRecord
  def account_suspended?
    account_status == 'suspended'
  end

  def account_deleted?
    account_status == 'deleted'
  end

  class << self
    IMPORT_COLUMNS = [
        :from_uid, :sort_order, :account_status,
        :uid, :screen_name, :friends_count, :followers_count,
        :protected, :suspended, :status_created_at, :account_created_at,
        :statuses_count, :favourites_count, :listed_count, :name,
        :location, :description, :url, :verified, :profile_image_url,
    ]

    def twitter_db_user_to_import_data(user)
      [
          user.uid,
          user.screen_name,
          user.friends_count,
          user.followers_count,
          user.protected,
          user.suspended,
          user.status_created_at,
          user.account_created_at,
          user.statuses_count,
          user.favourites_count,
          user.listed_count,
          user.name,
          user.location,
          user.description,
          user.url,
          user.verified,
          user.profile_image_url_https,
      ]
    end

    def raw_user_to_import_data(user)
      [
          user[:id],
          user[:screen_name],
          user[:friends_count] || -1,
          user[:followers_count] || -1,
          !!user[:protected],
          !!user[:suspended],
          user.dig(:status, :created_at),
          user[:created_at],
          user[:statuses_count] || -1,
          user[:favourites_count] || -1,
          user[:listed_count] || -1,
          user[:name] || '',
          user[:location] || '',
          cleaned_description(user) || '',
          cleaned_url(user) || '',
          !!user[:verified],
          user[:profile_image_url_https] || '',
      ]
    end

    def import_data(from_uid, raw_data)
      old_records = where(from_uid: from_uid).order(:sort_order)
      records_exist = old_records.exists?

      if raw_data[0].instance_of?(TwitterDB::User)
        data = raw_data.map.with_index do |user, index|
          d = twitter_db_user_to_import_data(user)
          d.prepend(from_uid, index, nil)
        end
      elsif raw_data[0].instance_of?(Hash)
        data = raw_data.map.with_index do |user, index|
          d = raw_user_to_import_data(user)
          d.prepend(from_uid, index, nil)
        end
      else
        raise "Incompatible data value=#{raw_data[0].class}"
      end

      if records_exist && old_records.pluck(:uid) == raw_data.map { |d| d[:id] }
        return
      end

      transaction do
        old_records.delete_all if records_exist
        import(IMPORT_COLUMNS, data, validate: false)
      end
    end

    def cleaned_description(data)
      if (text = data[:description]) && (entities = data.dig(:entities, :description, :urls))
        entities.each do |entity|
          text.gsub!(entity[:url], entity[:expanded_url])
        end
      end
      text
    rescue => e
      data[:description]
    end

    def cleaned_url(data)
      data.dig(:entities, :url, :urls, 0, :expanded_url) || data[:url]
    end
  end
end
