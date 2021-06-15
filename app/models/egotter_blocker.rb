# == Schema Information
#
# Table name: egotter_blockers
#
#  id         :bigint(8)        not null, primary key
#  uid        :bigint(8)        not null
#  created_at :datetime         not null
#
# Indexes
#
#  index_egotter_blockers_on_created_at  (created_at)
#  index_egotter_blockers_on_uid         (uid) UNIQUE
#
# TODO Remove later
class EgotterBlocker < ApplicationRecord
  validates :uid, presence: true, uniqueness: true
end
