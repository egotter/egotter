# == Schema Information
#
# Table name: search_requests
#
#  id            :bigint(8)        not null, primary key
#  user_id       :bigint(8)
#  uid           :bigint(8)
#  screen_name   :string(191)
#  status        :string(191)
#  properties    :json
#  error_class   :string(191)
#  error_message :text(65535)
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_search_requests_on_uid      (uid)
#  index_search_requests_on_user_id  (user_id)
#
class SearchRequest < ApplicationRecord
  ERROR_DETECTOR = lambda do |e|
    case
    when TwitterApiStatus.not_found?(e)
      'not found'
    when TwitterApiStatus.suspended?(e)
      'suspended'
    when TwitterApiStatus.unauthorized?(e)
      'unauthorized'
    when TwitterApiStatus.temporarily_locked?(e)
      'temporarily locked'
    when TwitterApiStatus.protected?(e)
      'protected'
    when TwitterApiStatus.blocked?(e)
      'blocked'
    else
      'unknown'
    end
  end

  def perform
    user = User.find_by(id: user_id)
    client = user ? user.api_client : Bot.api_client

    target_user = nil
    error = nil
    begin
      Timeout.timeout(3.seconds) do
        target_user = client.user(uid || screen_name)
      end
    rescue => e
      error = e
    end

    if error
      update(status: ERROR_DETECTOR.call(error), error_class: error.class, error_message: error.message)
      return
    end

    if target_user
      update(uid: target_user[:id])
    end

    begin
      Timeout.timeout(3.seconds) do
        client.twitter.user_timeline(uid, count: 1)
      end
    rescue => e
      error = e
    end

    if error
      update(status: ERROR_DETECTOR.call(error), error_class: error.class, error_message: error.message)
      return
    end

    if !user && SearchLimitation.soft_limited?(target_user)
      update(status: 'soft limit')
      return
    end

    if !user && target_user[:protected]
      update(status: 'protected account')
      return
    end

    if user && user.uid == target_user[:id]
      update(status: 'ok')
      return
    end

    if PrivateModeSetting.specified?(target_user[:id])
      update(status: 'private mode')
      return
    end

    if properties['remaining_count'] && properties['search_histories']
      if properties['remaining_count'] <= 0 && properties['search_histories'].exclude?(target_user[:id])
        update(status: 'too many searches')
        return
      end
    end

    if user && TooManyRequestsUsers.new.exists?(user.id)
      update(status: 'too many searches')
      return
    end

    if user && TooManyFriendsUsers.new.exists?(user.id)
      update(status: 'too many friends')
    end

    update(status: 'ok')
  end

  def ok?
    status == 'ok'
  end
end