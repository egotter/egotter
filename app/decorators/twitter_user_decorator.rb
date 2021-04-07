class TwitterUserDecorator < ApplicationDecorator
  delegate_all

  def mention_name
    "@#{screen_name}"
  end

  def delimited_statuses_count
    statuses_count.to_i.to_s(:delimited)
  end

  def delimited_friends_count
    friends_count.to_i.to_s(:delimited)
  end

  def delimited_followers_count
    followers_count.to_i.to_s(:delimited)
  end

  def status_interval_avg_in_words
    if status_interval_avg == 0
      0
    else
      h.time_ago_in_words(Time.zone.now - status_interval_avg) rescue nil
    end
  end

  def status_interval_text
    (value = status_interval_avg_in_words) == 0 ? '0' : (value || I18n.t('twitter.profile.counting'))
  end

  def percent_follow_back_rate
    h.number_to_percentage(follow_back_rate * 100, precision: 1) rescue nil
  end

  def percent_follow_back_rate_text
    percent_follow_back_rate || I18n.t('twitter.profile.counting')
  end

  def reverse_percent_follow_back_rate
    h.number_to_percentage(reverse_follow_back_rate * 100, precision: 1) rescue nil
  end

  def reverse_percent_follow_back_rate_text
    reverse_percent_follow_back_rate || I18n.t('twitter.profile.counting')
  end

  def account_created_at?
    account_created_at.present? && !account_created_at.kind_of?(String)
  end

  def censored_location
    if location&.match?(ADULT_ACCOUNT_REGEXP) && cannot_see_adult_account?
      I18n.t('twitter.censored_location')
    else
      location
    end
  rescue => e
    logger.warn "#{__method__}: Unhandled exception #{e.inspect} location=#{location}"
    location
  end

  def location?
    location.present?
  end

  def profile_url?
    url.present?
  end

  def profile_url
    url
  end

  def censored_profile_url
    if adult_account? && cannot_see_adult_account?
      I18n.t('twitter.censored_profile_url')
    else
      profile_url
    end
  end

  def censored_description
    if description&.match?(ADULT_ACCOUNT_REGEXP) && cannot_see_adult_account?
      I18n.t('twitter.censored_description')
    else
      description
    end
  rescue => e
    logger.warn "#{__method__}: Unhandled exception #{e.inspect} description=#{description}"
    description
  end

  def description?
    description.present?
  end

  def investor?
    description&.match?(/投資|Founder|ベンチャーキャピタル|VC|アーリーステージ|インキュベータ|インキュベーション/)
  end

  def engineer?
    description&.match?(/([Ee])ngineer|エンジニア|開発者|Python|Ruby|Golang|Java/)
  end

  def designer?
    description&.match?(/([Dd])esigner|デザイナ|イラストレータ/)
  end

  def bikini_model?
    description&.match?(/グラビア/)
  end

  def fashion_model?
    description&.match?(/モデル/)
  end

  def too_emotional?
    description&.match?(/精神疾患|自傷行為|障害年金\d級|精神\d級|発達障害|人格障害|双極|統失|セルフネグレクト|病み垢/)
  end

  def pop_idol?
    description&.match?(/アイドル/)
  end

  def has_instagram?
    description&.include?('instagram.com') || url&.include?('instagram.com')
  end

  def has_tiktok?
    description&.include?('tiktok.com') || url&.include?('tiktok.com')
  end

  def has_secret_account?
    description&.match?(/(裏|サブ)(垢|アカ)/)
  end

  ADULT_ACCOUNT_REGEXP = Regexp.new(File.read(Rails.root.join('config/adult_ng_words.txt')).split("\n").join('|'))

  def adult_account?
    name&.match?(ADULT_ACCOUNT_REGEXP) || description&.match?(ADULT_ACCOUNT_REGEXP) || location&.match?(ADULT_ACCOUNT_REGEXP)
  end

  def can_see_adult_account?
    if instance_variable_defined?(:@can_see_adult_account)
      @can_see_adult_account
    else
      @can_see_adult_account = h.user_signed_in? && (h.current_user.uid == object.uid || h.current_user.can_see_adult_account?)
    end
  end

  def cannot_see_adult_account?
    !can_see_adult_account?
  end

  def profile_icon_url?
    profile_image_url_https.present?
  end

  GRAY_100 = 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAGQAAABkCAIAAAD/gAIDAAAAGXRFWHRTb2Z0d2FyZQBBZG9iZSBJbWFnZVJlYWR5ccllPAAAAy5pVFh0WE1MOmNvbS5hZG9iZS54bXAAAAAAADw/eHBhY2tldCBiZWdpbj0i77u/IiBpZD0iVzVNME1wQ2VoaUh6cmVTek5UY3prYzlkIj8+IDx4OnhtcG1ldGEgeG1sbnM6eD0iYWRvYmU6bnM6bWV0YS8iIHg6eG1wdGs9IkFkb2JlIFhNUCBDb3JlIDUuNi1jMTQwIDc5LjE2MDMwMiwgMjAxNy8wMy8wMi0xNjo1OTozOCAgICAgICAgIj4gPHJkZjpSREYgeG1sbnM6cmRmPSJodHRwOi8vd3d3LnczLm9yZy8xOTk5LzAyLzIyLXJkZi1zeW50YXgtbnMjIj4gPHJkZjpEZXNjcmlwdGlvbiByZGY6YWJvdXQ9IiIgeG1sbnM6eG1wPSJodHRwOi8vbnMuYWRvYmUuY29tL3hhcC8xLjAvIiB4bWxuczp4bXBNTT0iaHR0cDovL25zLmFkb2JlLmNvbS94YXAvMS4wL21tLyIgeG1sbnM6c3RSZWY9Imh0dHA6Ly9ucy5hZG9iZS5jb20veGFwLzEuMC9zVHlwZS9SZXNvdXJjZVJlZiMiIHhtcDpDcmVhdG9yVG9vbD0iQWRvYmUgUGhvdG9zaG9wIEVsZW1lbnRzIDE2LjAgKE1hY2ludG9zaCkiIHhtcE1NOkluc3RhbmNlSUQ9InhtcC5paWQ6MzczODMxNkM1MDQyMTFFQkEwMUVBNzBERkMwMUQ5QjEiIHhtcE1NOkRvY3VtZW50SUQ9InhtcC5kaWQ6RTM3QkUwMzY1MTM3MTFFQkEwMUVBNzBERkMwMUQ5QjEiPiA8eG1wTU06RGVyaXZlZEZyb20gc3RSZWY6aW5zdGFuY2VJRD0ieG1wLmlpZDozNzM4MzE2QTUwNDIxMUVCQTAxRUE3MERGQzAxRDlCMSIgc3RSZWY6ZG9jdW1lbnRJRD0ieG1wLmRpZDozNzM4MzE2QjUwNDIxMUVCQTAxRUE3MERGQzAxRDlCMSIvPiA8L3JkZjpEZXNjcmlwdGlvbj4gPC9yZGY6UkRGPiA8L3g6eG1wbWV0YT4gPD94cGFja2V0IGVuZD0iciI/PlRKEtUAAACiSURBVHja7NAxAQAACAMgtX+0hbKCnw9EoJMUN6NAlixZsmTJUiBLlixZsmQpkCVLlixZshTIkiVLlixZCmTJkiVLliwFsmTJkiVLlgJZsmTJkiVLgSxZsmTJkqVAlixZsmTJUiBLlixZsmQpkCVLlixZshTIkiVLlixZCmTJkiVLliwFsmTJkiVLlgJZsmTJkiVLgSxZsmTJkqVAlqxvK8AAh5UDLHJQma8AAAAASUVORK5CYII='

  def censored_profile_icon_url(size = nil)
    if adult_account? && cannot_see_adult_account?
      GRAY_100
    else
      profile_icon_url(size)
    end
  end

  def profile_icon_url(size = nil)
    if size == 'bigger'
      profile_image_url_https.to_s.gsub(/_normal(\.jpe?g|\.png|\.gif)$/, '_bigger\1')
    else
      profile_image_url_https.remove('_normal')
    end
  end

  def url_label
    url.remove(/^https?:\/\//).truncate(30)
  end

  def profile_banner_url?
    profile_banner_url.present?
  end

  def profile_banner_url_for(request)
    # suffix = request.from_pc? ? 'web_retina' : 'mobile_retina'
    suffix = '1080x360'
    "#{profile_banner_url}/#{suffix}"
  end

  def profile_link_color_code
    "##{profile_link_color}"
  end

  def suspended_label
    if suspended?
      h.tag.span(class: 'badge badge-danger') { I18n.t('twitter.profile.labels.suspended') }
    end
  end

  def blocked_label
    if blocked?
      h.tag.span(class: 'badge badge-secondary') { I18n.t('twitter.profile.labels.blocked') }
    end
  end


  def inactive_2weeks_label
    if !suspended? && inactive_2weeks?
      h.tag.span(class: 'badge badge-secondary') { I18n.t('twitter.profile.labels.inactive_2weeks') }
    end
  end

  def inactive_1month_label
    if !suspended? && inactive_1month?
      h.tag.span(class: 'badge badge-secondary') { I18n.t('twitter.profile.labels.inactive_1month') }
    end
  end

  def inactive_3months_label
    if !suspended? && inactive_3months?
      h.tag.span(class: 'badge badge-secondary') { I18n.t('twitter.profile.labels.inactive_3months') }
    end
  end

  def inactive_6months_label
    if !suspended? && inactive_6months?
      h.tag.span(class: 'badge badge-secondary') { I18n.t('twitter.profile.labels.inactive_6months') }
    end
  end

  def inactive_1year_label
    if !suspended? && inactive_1year?
      h.tag.span(class: 'badge badge-secondary') { I18n.t('twitter.profile.labels.inactive_1year') }
    end
  end

  def refollow_label
    if refollow?
      h.tag.span(class: 'badge badge-info') { I18n.t('twitter.profile.labels.refollow') }
    end
  end

  def refollowed_label
    if refollowed?
      h.tag.span(class: 'badge badge-info') { I18n.t('twitter.profile.labels.refollowed') }
    end
  end

  def followed_label
    h.tag.span(class: 'badge badge-secondary') { I18n.t('twitter.profile.labels.followed') }
  end

  def status_labels
    [
        suspended_label,
        blocked_label,
        inactive_1year_label || inactive_6months_label || inactive_3months_label || inactive_1month_label || inactive_2weeks_label,
        refollow_label,
        refollowed_label,
    ].compact.join('&nbsp;').html_safe
  end

  def single_followed_label
    h.tag.span(class: 'text-muted small') do |tag|
      tag.i(class: 'fas fa-user') + '&nbsp;'.html_safe + I18n.t('twitter.profile.labels.followed')
    end
  end

  def protected_icon
    if protected_account?
      h.tag.i(class: 'fas fa-lock text-warning')
    end
  end

  def verified_icon
    if verified_account?
      h.tag.i(class: 'fas fa-check text-primary')
    end
  end

  def censored_name
    if name&.match?(ADULT_ACCOUNT_REGEXP) && cannot_see_adult_account?
      I18n.t('twitter.censored_name')
    else
      name
    end
  rescue => e
    logger.warn "#{__method__}: Unhandled exception #{e.inspect} name=#{name}"
    name
  end

  # TODO Rename to name_with_badges
  def name_with_icon
    [
        censored_name,
        protected_icon,
        verified_icon
    ].compact.join('&nbsp;').html_safe
  end

  def to_param
    screen_name
  end

  def suspended?
    if context.has_key?(:suspended_uids)
      context[:suspended_uids].include?(uid)
    else
      object.suspended
    end
  end

  def blocked?
    if context.has_key?(:blocking_uids)
      context[:blocking_uids].include?(uid)
    end
  end

  def updated
    if object.updated_at > 1.hour.ago
      text = h.time_ago_in_words(object.updated_at)
    else
      text = I18n.l(object.updated_at.in_time_zone('Tokyo'), format: :profile_header_long)
    end
    I18n.t('twitter.profile.updated_at', text: text)
  end

  def active?
    !inactive_2weeks?
  end

  def inactive_2weeks?
    inactive_period?(2.weeks)
  end

  def inactive_1month?
    inactive_period?(1.month)
  end

  def inactive_3months?
    inactive_period?(3.months)
  end

  def inactive_6months?
    inactive_period?(6.months)
  end

  def inactive_1year?
    inactive_period?(1.year)
  end

  def protected_account?
    object.protected
  end

  def verified_account?
    verified
  end

  def has_more_friends?
    object.friends_count > object.followers_count
  end

  def has_more_followers?
    object.followers_count > object.friends_count
  end

  private

  def refollow?
    if context.has_key?(:friend_uids)
      context[:friend_uids].include?(uid)
    end
  end

  def refollowed?
    if context.has_key?(:follower_uids)
      context[:follower_uids].include?(uid)
    end
  end

  def inactive_period?(duration)
    object.status_created_at && object.status_created_at < duration.ago
  end
end
