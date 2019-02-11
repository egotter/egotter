# == Schema Information
#
# Table name: unfollow_requests
#
#  id            :integer          not null, primary key
#  user_id       :integer          not null
#  uid           :bigint(8)        not null
#  finished_at   :datetime
#  error_class   :string(191)      default(""), not null
#  error_message :string(191)      default(""), not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_unfollow_requests_on_created_at  (created_at)
#  index_unfollow_requests_on_user_id     (user_id)
#

class UnfollowRequest < ApplicationRecord
  include Concerns::Request::FollowAndUnfollow

  belongs_to :user
  validates :user_id, numericality: :only_integer
  validates :uid, numericality: :only_integer

  def ready?
    Concerns::User::FollowAndUnfollow::Util.global_can_create_unfollow? && user.can_create_unfollow?
  end

  def perform!(client = nil)
    client = user.api_client.twitter unless client

    raise Concerns::FollowAndUnfollowWorker::CanNotUnfollowYourself if user.uid == uid
    raise Concerns::FollowAndUnfollowWorker::HaveNotFollowed unless client.friendship?(user.uid, uid)

    client.unfollow(uid)
    finished!
  end

  def perform(client = nil)
    perform!(client)
  rescue Concerns::FollowAndUnfollowWorker::CanNotUnfollowYourself, Concerns::FollowAndUnfollowWorker::HaveNotFollowed => e
    update(error_class: e.class, error_message: e.message.truncate(150))
  end
end
