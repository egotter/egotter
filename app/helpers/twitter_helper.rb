module TwitterHelper
  def user_url(screen_name)
    "https://twitter.com/#{screen_name}"
  end

  def direct_message_url(uid)
    "https://twitter.com/messages/compose?recipient_id=#{uid}"
  end

  def follow_url(screen_name)
    "https://twitter.com/intent/follow?screen_name=#{screen_name}"
  end

  def user_link(screen_name, options = {}, &block)
    options = options.merge(target: '_blank', rel: 'nofollow')
    url = "https://twitter.com/#{screen_name}"
    block_given? ? link_to(url, options, &block) : link_to(mention_name(screen_name), url, options)
  end

  def tweet_url(screen_name, tweet_id)
    "https://twitter.com/#{screen_name}/status/#{tweet_id}"
  end

  def tweet_link(tweet)
    time_ago = time_ago_in_words(tweet.try(:tweeted_at) || tweet.created_at)
    tweet_id = tweet.try(:tweet_id) || tweet.id
    link_to time_ago, tweet_url(tweet.user.screen_name, tweet_id), target: '_blank', rel: 'nofollow'
  end

  def intent_url(text, params = {})
    params = params.merge(text: text).to_param
    "https://twitter.com/intent/tweet?#{params}"
  end

  def linkify(text)
    url = timeline_path(screen_name: 'SN').sub(/SN$/, '\\\1')
    text.gsub(/@(\w+)/, %Q{<a href="#{url}">\\0</a>}).html_safe
  end

  def mention_name(screen_name)
    "@#{screen_name}"
  end

  def user_name(user, label: false)
    protected = user.protected ? '&nbsp;<span class="glyphicon glyphicon-lock"></span>' : ''
    verified = user.verified ? '&nbsp;<span class="glyphicon glyphicon-ok"></span>' : ''
    "#{user.name}#{protected}#{verified}#{user_label(user) if label}".html_safe
  end

  def user_label(user)
    suspended  = user.suspended ? '&nbsp;<span class="label label-danger">' + t('dictionary.suspended') + '</span>' : ''
    blocked    = (user.respond_to?(:blocked) && user.blocked) ? '&nbsp;<span class="label label-default">' + t('dictionary.blocked') + '</span>' : ''
    inactive   = (!user.suspended && user.inactive) ? '&nbsp;<span class="label label-default">' + t('dictionary.inactive') + '</span>' : ''
    refollow   = (user.respond_to?(:refollow) && user.refollow) ? '&nbsp;<span class="label label-info">' + t('dictionary.refollow') + '</span>' : ''
    refollowed = (user.respond_to?(:refollowed) && user.refollowed) ? '&nbsp;<span class="label label-info">' + t('dictionary.refollowed') + '</span>' : ''
    "#{suspended}#{blocked}#{inactive}#{refollow}#{refollowed}".html_safe
  end

  def normal_icon_url(user)
    user.profile_image_url_https.to_s
  end

  def normal_icon_img(user, options = {})
    image_tag normal_icon_url(user), {size: '48x48', alt: user.screen_name}.merge(options)
  end

  def bigger_icon_url(user)
    user.profile_image_url_https.to_s.gsub(/_normal(\.jpg$)/, '_bigger\1')
  end

  def bigger_icon_img(user, options = {})
    image_tag bigger_icon_url(user), {size: '73x73', alt: user.screen_name}.merge(options)
  end
end
