# == Schema Information
#
# Table name: jobs
#
#  id              :integer          not null, primary key
#  track_id        :integer          default(-1), not null
#  user_id         :integer          default(-1), not null
#  uid             :integer          default(-1), not null
#  screen_name     :string(191)      default(""), not null
#  twitter_user_id :integer          default(-1), not null
#  client_uid      :integer          default(-1), not null
#  jid             :string(191)      default(""), not null
#  parent_jid      :string(191)      default(""), not null
#  worker_class    :string(191)      default(""), not null
#  error_class     :string(191)      default(""), not null
#  error_message   :string(191)      default(""), not null
#  enqueued_at     :datetime
#  started_at      :datetime
#  finished_at     :datetime
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_jobs_on_created_at   (created_at)
#  index_jobs_on_jid          (jid)
#  index_jobs_on_screen_name  (screen_name)
#  index_jobs_on_track_id     (track_id)
#  index_jobs_on_uid          (uid)
#

class Job < ActiveRecord::Base
  belongs_to :track

  def twitter_user_created?
    twitter_user_id != -1
  end

  def processing?
    !!started_at && !finished_at
  end

  def finished?
    !!finished_at
  end

  def failed?
    error_class.present? || error_message.present?
  end

  class Error < StandardError
    Unauthorized = Class.new(self)
    TooOldOrTooBusy = Class.new(self)
    RecentlyEnqueued = Class.new(self)
    NotChanged = Class.new(self)
    RecordInvalid = Class.new(self)
  end
end
