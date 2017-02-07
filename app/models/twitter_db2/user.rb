# == Schema Information
#
# Table name: users
#
#  id               :integer          not null, primary key
#  uid              :string(191)      not null
#  screen_name      :string(191)      not null
#  authorized       :boolean          default(TRUE), not null
#  secret           :string(191)      not null
#  token            :string(191)      not null
#  email            :string(191)      default(""), not null
#  first_access_at  :datetime
#  last_access_at   :datetime
#  first_search_at  :datetime
#  last_search_at   :datetime
#  first_sign_in_at :datetime
#  last_sign_in_at  :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_users_on_created_at   (created_at)
#  index_users_on_screen_name  (screen_name)
#  index_users_on_uid          (uid) UNIQUE
#

module TwitterDB2
  class User < ActiveRecord::Base
    self.table_name = 'twitter_db_users'

    include Concerns::TwitterUser::Store
    include Concerns::TwitterUser::Inflections

    with_options primary_key: :uid, foreign_key: :user_uid, dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friendships, -> { order(sequence: :asc) }, class_name: 'TwitterDB2::Friendship'
      obj.has_many :followerships, -> { order(sequence: :asc) }, class_name: 'TwitterDB2::Followership'
    end

    with_options dependent: :destroy, validate: false, autosave: false do |obj|
      obj.has_many :friends,   through: :friendships, class_name: 'TwitterDB2::User'
      obj.has_many :followers, through: :followerships, class_name: 'TwitterDB2::User'
    end
  end
end
