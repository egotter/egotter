module Api
  module V1
    class RecentUsersController < ApplicationController
      def index
        users = fetch_users
        users = users.map { |user| user_to_hash(user) }
        render json: {users: users}
      end

      private

      def fetch_users(limit = 10)
        twitter_users = TwitterUser.select(:uid).order(created_at: :desc).limit(limit)
        users = TwitterDB::User.where(uid: twitter_users.map(&:uid))
        users.map { |user| TwitterUserDecorator.new(user) }
      end

      GRAY_300X100 = 'data:image/gif;base64,R0lGODlhLAFkAIAAAMzMzAAAACH/C1hNUCBEYXRhWE1QPD94cGFja2V0IGJlZ2luPSLvu78iIGlkPSJXNU0wTXBDZWhpSHpyZVN6TlRjemtjOWQiPz4gPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iQWRvYmUgWE1QIENvcmUgNS42LWMxNDAgNzkuMTYwMzAyLCAyMDE3LzAzLzAyLTE2OjU5OjM4ICAgICAgICAiPiA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPiA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIiB4bWxuczp4bXA9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC8iIHhtbG5zOnhtcE1NPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvbW0vIiB4bWxuczpzdFJlZj0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL3NUeXBlL1Jlc291cmNlUmVmIyIgeG1wOkNyZWF0b3JUb29sPSJBZG9iZSBQaG90b3Nob3AgRWxlbWVudHMgMTYuMCAoTWFjaW50b3NoKSIgeG1wTU06SW5zdGFuY2VJRD0ieG1wLmlpZDpBMzc0ODJGOTkzMkYxMUVCQTA0MUQ5OUI0NUE1NzcwOCIgeG1wTU06RG9jdW1lbnRJRD0ieG1wLmRpZDpBMzc0ODJGQTkzMkYxMUVCQTA0MUQ5OUI0NUE1NzcwOCI+IDx4bXBNTTpEZXJpdmVkRnJvbSBzdFJlZjppbnN0YW5jZUlEPSJ4bXAuaWlkOkEzNzQ4MkY3OTMyRjExRUJBMDQxRDk5QjQ1QTU3NzA4IiBzdFJlZjpkb2N1bWVudElEPSJ4bXAuZGlkOkEzNzQ4MkY4OTMyRjExRUJBMDQxRDk5QjQ1QTU3NzA4Ii8+IDwvcmRmOkRlc2NyaXB0aW9uPiA8L3JkZjpSREY+IDwveDp4bXBtZXRhPiA8P3hwYWNrZXQgZW5kPSJyIj8+Af/+/fz7+vn49/b19PPy8fDv7u3s6+rp6Ofm5eTj4uHg397d3Nva2djX1tXU09LR0M/OzczLysnIx8bFxMPCwcC/vr28u7q5uLe2tbSzsrGwr66trKuqqainpqWko6KhoJ+enZybmpmYl5aVlJOSkZCPjo2Mi4qJiIeGhYSDgoGAf359fHt6eXh3dnV0c3JxcG9ubWxramloZ2ZlZGNiYWBfXl1cW1pZWFdWVVRTUlFQT05NTEtKSUhHRkVEQ0JBQD8+PTw7Ojk4NzY1NDMyMTAvLi0sKyopKCcmJSQjIiEgHx4dHBsaGRgXFhUUExIREA8ODQwLCgkIBwYFBAMCAQAAIfkEAAAAAAAsAAAAACwBZAAAAtuEj6nL7Q+jnLTai7PevPsPhuJIluaJpurKtu4Lx/JM1/aN5/rO9/4PDAqHxKLxiEwql8ym8wmNSqfUqvWKzWq33K73Cw6Lx+Sy+YxOq9fstvsNj8vn9Lr9js/r9/y+/w8YKDhIWGh4iJiouMjY6PgIGSk5SVlpeYmZqbnJ2en5CRoqOkpaanqKmqq6ytrq+gobKztLW2t7i5uru8vb6/sLHCw8TFxsfIycrLzM3Oz8DB0tPU1dbX2Nna29zd3t/Q0eLj5OXm5+jp6uvs7e7v4OHy8/T19vf48vVwAAOw=='

      def user_to_hash(user)
        {
            screen_name: user.screen_name,
            name: user.name,
            profile_image: user.profile_icon_url,
            profile_banner: user.profile_banner_url? ? user.profile_banner_url_for('300x100') : GRAY_300X100,
            timeline_url: timeline_path(user, via: current_via),
        }
      end
    end
  end
end
