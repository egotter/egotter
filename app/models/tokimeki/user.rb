# == Schema Information
#
# Table name: tokimeki_users
#
#  id              :bigint(8)        not null, primary key
#  uid             :bigint(8)        not null
#  screen_name     :string(191)      not null
#  friends_count   :integer          default(0), not null
#  processed_count :integer          default(0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_tokimeki_users_on_created_at  (created_at)
#  index_tokimeki_users_on_uid         (uid) UNIQUE
#

module Tokimeki
  class User < ApplicationRecord
    default_options = {dependent: :destroy, validate: false, autosave: false}
    order_by_sequence_asc = -> {order(sequence: :asc)}

    with_options default_options.merge(primary_key: :uid, foreign_key: :user_uid) do |obj|
      obj.has_many :friendships, order_by_sequence_asc, class_name: 'Tokimeki::Friendship'
      obj.has_many :unfriendships, order_by_sequence_asc, class_name: 'Tokimeki::Unfriendship'
    end

    with_options default_options.merge(class_name: 'Tokimeki::User') do |obj|
      obj.has_many :friends, through: :friendships
      obj.has_many :unfriends, through: :friendships
    end
  end
end
