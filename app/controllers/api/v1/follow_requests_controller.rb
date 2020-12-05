module Api
  module V1
    class FollowRequestsController < ApplicationController

      before_action :reject_crawler
      before_action :require_login!
      before_action { valid_uid?(params[:uid], only_validation: true) }
      before_action :cannot_follow_yourself
      before_action :create_egotter_follower
      before_action :limit_requests_count

      def create
        request = FollowRequest.create!(user_id: current_user.id, uid: params[:uid], requested_by: "follows#create via=#{params[:via]}")
        screen_name = fetch_target_screen_name(params[:uid])
        rate_limit = RateLimit.new(current_user)
        job_args = [request.id, enqueue_location: controller_name]

        if GlobalFollowLimitation.new.limited?
          CreateFollowWorker.perform_in(1.hour + rand(30.minutes), *job_args)
          message = t('.success_with_delay', user: screen_name)
        else
          if request.uid == User::EGOTTER_UID
            CreateFollowWorker.perform_in(30.seconds, *job_args)
          else
            CreateFollowWorker.perform_async(*job_args)
          end
          message = t('.success', user: screen_name, count: rate_limit.remaining)
        end

        render json: {request_id: request.id, message: message}.merge(rate_limit.to_h)
      end

      private

      def cannot_follow_yourself
        if params[:uid].to_i == current_user.uid
          render json: {message: t('.create.cannot_follow_yourself')}, status: :bad_request
        end
      end

      def create_egotter_follower
        if params[:uid].to_i == User::EGOTTER_UID
          CreateEgotterFollowerWorker.perform_async(current_user.id)
        end
      end

      def limit_requests_count
        if CreateFollowLimitation.remaining_count(current_user) <= 0
          render json: RateLimit.new(current_user).to_h, status: :too_many_requests
        end
      end

      def fetch_target_screen_name(uid)
        user = TwitterDB::User.find_by(uid: uid)
        user = TwitterUser.latest_by(uid: uid) unless user
        user ? user.screen_name : uid
      end

      class RateLimit
        attr_reader :limit, :remaining

        def initialize(user)
          @limit = CreateFollowLimitation.max_count(user)
          @remaining = CreateFollowLimitation.remaining_count(user)
        end

        def to_h
          {limit: limit, remaining: remaining}
        end
      end
    end
  end
end
