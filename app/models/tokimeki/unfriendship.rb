# == Schema Information
#
# Table name: tokimeki_unfriendships
#
#  id         :bigint(8)        not null, primary key
#  user_uid   :bigint(8)        not null
#  friend_uid :bigint(8)        not null
#  sequence   :integer          not null
#
# Indexes
#
#  index_tokimeki_unfriendships_on_friend_uid  (friend_uid)
#  index_tokimeki_unfriendships_on_user_uid    (user_uid)
#

module Tokimeki
  class Unfriendship < ApplicationRecord
    with_options(primary_key: :uid, class_name: 'Tokimeki::User', optional: true) do |obj|
      obj.belongs_to :user
      obj.belongs_to :unfriend, foreign_key: :friend_uid
    end
  end
end
