module TwitterHelper
  def user_url(screen_name)
    "https://twitter.com/#{screen_name}"
  end

  def user_link(screen_name, options = {}, &block)
    options = options.merge(target: '_blank')
    url = "https://twitter.com/#{screen_name}"
    block_given? ? link_to(url, options, &block) : link_to(mention_name(screen_name), url, options)
  end

  def tweet_url(screen_name, tweet_id)
    "https://twitter.com/#{screen_name}/status/#{tweet_id}"
  end

  def intent_url(text, params = {})
    params = params.merge(text: text).to_param
    "https://twitter.com/intent/tweet?#{params}"
  end

  def mention_name(screen_name)
    "@#{screen_name}"
  end

  def user_name(user)
    protected = '&nbsp;<span class="glyphicon glyphicon-lock"></span>'
    verified = '&nbsp;<span class="glyphicon glyphicon-ok"></span>'
    "#{user.name}#{protected if user.protected}#{verified if user.verified}".html_safe
  end
end
