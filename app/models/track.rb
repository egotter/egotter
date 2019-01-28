# == Schema Information
#
# Table name: tracks
#
#  id          :integer          not null, primary key
#  session_id  :string(191)      default(""), not null
#  user_id     :integer          default(-1), not null
#  uid         :integer          default(-1), not null
#  screen_name :string(191)      default(""), not null
#  controller  :string(191)      default(""), not null
#  action      :string(191)      default(""), not null
#  auto        :boolean          default(FALSE), not null
#  via         :string(191)      default(""), not null
#  device_type :string(191)      default(""), not null
#  os          :string(191)      default(""), not null
#  browser     :string(191)      default(""), not null
#  user_agent  :string(191)      default(""), not null
#  referer     :string(191)      default(""), not null
#  referral    :string(191)      default(""), not null
#  channel     :string(191)      default(""), not null
#  medium      :string(191)      default(""), not null
#  created_at  :datetime         not null
#
# Indexes
#
#  index_tracks_on_created_at  (created_at)
#

class Track < ApplicationRecord
  has_many :jobs, dependent: :destroy, validate: false, autosave: true
end
