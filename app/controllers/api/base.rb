module Api
  class Base < ApplicationController
    include SearchesHelper
    include Validation

    layout false

    # before_action -> { head :bad_request }, unless: -> { params[:token] }
    # skip_before_action :verify_authenticity_token

    before_action -> { valid_uid?(params[:uid].to_i) }
    before_action -> { existing_uid?(params[:uid].to_i) }
    before_action -> { @twitter_user = TwitterUser.latest(params[:uid].to_i) }
    before_action -> { authorized_search?(@twitter_user) }

    def summary
      uids, size = summary_uids
      users = TwitterDB::User.where(uid: uids).index_by(&:uid)

      # TODO Debug
      if uids.any? { |uid| !users.has_key?(uid) }
        logger.warn "#{self.class}##{__method__}: Not persisted #{uids.select { |uid| !users.has_key?(uid) }.inspect}"
      end

      users = uids.map { |uid| users[uid] }.compact.map {|user| Hashie::Mash.new(to_summary_hash(user))}

      chart = [{name: t("charts.#{controller_name}"), y: 100.0 / 3.0}, {name: t('charts.others'),  y: 200.0 / 3.0}]

      render json: {name: controller_name, count: size, users: users, chart: chart}, status: 200
    end

    def list
      limit = (0..10).include?(params[:limit].to_i) ? params[:limit].to_i : 10
      uids, max_sequence = list_uids(params[:max_sequence].to_i, limit: limit)

      suspended_uids = fetch_suspended_uids(uids)

      users = TwitterDB::User.where(uid: uids).index_by(&:uid)
      users = uids.map { |uid| users[uid] }.compact.map do |user|
        suspended = suspended_uids.include?(user.uid)
        Hashie::Mash.new(to_list_hash(user, suspended: suspended))
      end

      if params[:html]
        users = render_to_string partial: 'twitter/user', collection: users, cached: true, formats: %i(html)
      end

      render json: {name: controller_name, max_sequence: max_sequence, limit: limit, users: users}, status: 200
    end

    private

    # TODO Experimental
    def fetch_suspended_uids(uids)
      if uids.any? && %w(unfriends unfollowers blocking_or_blocked).include?(controller_name)
        uids - client.users(uids).map(&:id)
      else
        []
      end
    rescue => e
      if e.message != 'No user matches for specified terms.'
        logger.warn "#{self.class}##{__method__}: #{e.class} #{e.message} #{params.inspect}"
      end
      []
    end

    def to_summary_hash(user)
      {
        uid: user.uid.to_s,
        screen_name: user.screen_name,
        profile_image_url_https: user.profile_image_url_https.to_s
      }
    end

    def to_list_hash(user, suspended: false)
      {
        uid: user.uid.to_s,
        screen_name: user.screen_name,
        name: user.name,
        profile_image_url_https: user.profile_image_url_https.to_s,
        description: user.description,
        protected: user.protected,
        verified: user.verified,
        suspended: suspended,
        inactive: user.inactive
      }
    end
  end
end