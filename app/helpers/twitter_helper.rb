module TwitterHelper
  # TODO Remove
  def user_url(screen_name)
    twitter_web_url(screen_name)
  end

  def twitter_web_url(screen_name)
    "https://twitter.com/#{screen_name}"
  end

  def twitter_web_link(screen_name)
    link_to '@' + screen_name, twitter_web_url(screen_name), target: '_blank'
  end

  def direct_message_url(uid, text = nil)
    text = "&text=#{CGI.escape(text)}" if text
    "https://twitter.com/messages/compose?recipient_id=#{uid}#{text}"
  end

  def twitter_search_url(query)
    "https://twitter.com/search?q=#{CGI.escape(query)}"
  end

  def direct_message_link(uid, screen_name, text = nil)
    link_to '@' + screen_name, direct_message_url(uid, text), target: '_blank'
  end

  def direct_messages_url(screen_name)
    "https://twitter.com/direct_messages/create/#{screen_name}"
  end

  def follow_intent_url(screen_name)
    "https://twitter.com/intent/follow?screen_name=#{screen_name}"
  end

  def user_link(screen_name, options = {}, &block)
    options = options.merge(target: '_blank', rel: 'nofollow')
    url = user_url(screen_name)
    block_given? ? link_to(url, options, &block) : link_to(mention_name(screen_name), url, options)
  end

  def tweet_url(screen_name, tweet_id)
    "https://twitter.com/#{screen_name}/status/#{tweet_id}"
  end

  def tweet_link(tweet)
    time_ago = time_ago_in_words(tweet.try(:tweeted_at) || tweet.created_at)
    tweet_id = tweet.try(:tweet_id) || tweet.id
    link_to time_ago, tweet_url(tweet.user&.screen_name, tweet_id), target: '_blank', rel: 'nofollow'
  end

  LINKIFY_USERNAME_URL_BASE = 'https://egotter.com/timelines/' # timeline_path

  def linkify(text)
    return '' if text.blank?

    link_attribute_block = lambda do |entity, attributes|
      if entity[:screen_name]
        attributes.delete(:rel)
        attributes[:href] = "#{LINKIFY_USERNAME_URL_BASE}#{entity[:screen_name]}?via=link_by_linkify"
      end
    end
    link_text_block = lambda do |entity, str|
      if entity[:url]
        str.remove(/^https?:\/\/(www\.)?/)
      else
        str
      end
    end
    TwitterTextAutoLink.auto_link(text, username_include_symbol: true, link_attribute_block: link_attribute_block, link_text_block: link_text_block).html_safe
  rescue => e
    Airbag.warn "linkify: #{e.inspect} text=#{text}"
    Airbag.info e.backtrace.join("\n")
    text
  end

  module TwitterTextAutoLink
    extend Twitter::TwitterText::Autolink
  end

  # TODO Deprecated
  def mention_name(screen_name)
    "@#{screen_name}"
  end

  def bigger_icon_url(user)
    user.profile_image_url_https.to_s.gsub(/_normal(\.jpe?g|\.png|\.gif)$/, '_bigger\1')
  end

  def egotter_icon_url
    image_path('/logo_transparent_96x96.png')
  end
end
