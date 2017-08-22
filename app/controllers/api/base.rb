module Api
  class Base < ApplicationController
    include SearchesHelper
    include Validation

    layout false

    # before_action -> { head :bad_request }, unless: -> { params[:token] }
    # skip_before_action :verify_authenticity_token

    before_action -> { valid_uid?(params[:uid].to_i) }
    before_action -> { existing_uid?(params[:uid].to_i) }
    before_action -> { twitter_db_user_persisted?(params[:uid].to_i) }
    before_action -> { @twitter_user = TwitterUser.latest(params[:uid].to_i) }
    before_action -> { authorized_search?(@twitter_user) }

    def summary
      uids, size = summary_uids
      users = TwitterDB::User.where(uid: uids).index_by(&:uid)

      if uids.any? { |uid| !users.has_key?(uid) }
        CreateTwitterDBUserWorker.perform_async(uids.select { |uid| !users.has_key?(uid) })
      end

      users = uids.map { |uid| users[uid] }.compact.map {|user| Hashie::Mash.new(to_summary_hash(user))}

      chart = [{name: t("charts.#{controller_name}"), y: 100.0 / 3.0}, {name: t('charts.others'),  y: 200.0 / 3.0}]

      render json: {name: controller_name, count: size, users: users, chart: chart}, status: 200
    end

    def list
      limit = (0..10).include?(params[:limit].to_i) ? params[:limit].to_i : 10
      uids, max_sequence = list_uids(params[:max_sequence].to_i, limit: limit)

      if uids.empty?
        return render json: {name: controller_name, max_sequence: max_sequence, limit: limit, users: []}, status: 200
      end

      suspended_uids = fetch_suspended_uids? ? fetch_suspended_uids(uids) : []
      blocking_uids = fetch_blocking_uids? ? fetch_blocking_uids : []
      friend_uids = confirm_refollow_uids? ? current_user.twitter_user.friendships.where(friend_uid: uids).pluck(:friend_uid) : []
      follower_uids = confirm_refollowed_uids? ? current_user.twitter_user.followerships.where(follower_uid: uids).pluck(:follower_uid) : []

      users = TwitterDB::User.where(uid: uids).index_by(&:uid)
      users =
        uids.map { |uid| users[uid] }.compact.map do |user|
          suspended = suspended_uids.include?(user.uid)
          blocked = blocking_uids.include?(user.uid)
          refollow = friend_uids.include?(user.uid)
          refollowed = follower_uids.include?(user.uid)
          Hashie::Mash.new(to_list_hash(user, suspended: suspended, blocked: blocked, refollow: refollow, refollowed: refollowed))
        end

      if params[:html]
        users = render_to_string partial: 'twitter/user', collection: users, cached: true, formats: %i(html)
      end

      render json: {name: controller_name, max_sequence: max_sequence, limit: limit, users: users}, status: 200
    end

    private

    def fetch_suspended_uids?
      %w(unfriends unfollowers blocking_or_blocked).include?(controller_name)
    end

    def fetch_suspended_uids(uids)
      uids - client.users(uids).map(&:id)
    rescue => e
      if e.message == 'No user matches for specified terms.'
      elsif e.message == 'Invalid or expired token.'
      else
        logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{params.inspect}"
      end
      []
    end

    def fetch_blocking_uids?
      fetch_suspended_uids? && user_signed_in?
    end

    def fetch_blocking_uids
      client.blocked_ids.to_a
    rescue => e
      if e.message == 'Invalid or expired token.'
      else
        logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{params.inspect}"
      end
      []
    end

    def confirm_refollow_uids?
      %w(unfriends blocking_or_blocked).include?(controller_name) && user_signed_in?
    end

    def confirm_refollowed_uids?
      %w(unfollowers blocking_or_blocked).include?(controller_name) && user_signed_in?
    end

    def to_summary_hash(user)
      {
        uid: user.uid.to_s,
        screen_name: user.screen_name,
        profile_image_url_https: user.profile_image_url_https.to_s
      }
    end

    def to_list_hash(user, suspended: false, blocked: false, refollow: false, refollowed: false)
      {
        uid: user.uid.to_s,
        screen_name: user.screen_name,
        name: user.name,
        profile_image_url_https: user.profile_image_url_https.to_s,
        description: user.description,
        protected: user.protected,
        verified: user.verified,
        suspended: suspended,
        blocked: blocked,
        refollow: refollow,
        refollowed: refollowed,
        inactive: user.inactive
      }
    end
  end
end