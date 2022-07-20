module CrawlersHelper
  def reject_crawler
    head :forbidden if from_crawler?
  end

  def from_crawler?
    return false if stripe_webhook?
    request.from_crawler? || from_minor_crawler?(request.user_agent)
  end

  # TODO Remove later
  def from_webhook?
    twitter_webhook? || stripe_webhook?
  end

  def stripe_webhook?
    request.user_agent.to_s.match?(/\AStripe/) && (controller_name == 'orders' || controller_name == 'stripe_webhook')
  end

  def twitter_webhook?
    request.user_agent.to_s == '' && controller_name == 'webhook'
  end

  def twitter_crawler?
    request.user_agent.to_s.match?(/^Twitterbot/) || (request.from_crawler? && request.browser == 'twitter')
  end

  def twitter_dm_crawler?
    twitter_crawler? && params[:medium] == 'dm'
  end

  def google_crawler?
    request.user_agent.to_s == 'Mediapartners-Google'

  end

  SEARCH_ENGINES = [
      'https://www.google.co.jp/',
      'https://www.google.com/',
      'https://search.yahoo.co.jp/',
  ]

  # TODO Rename to #user_from_search_engine?
  def from_search_engine?
    !from_crawler? && SEARCH_ENGINES.include?(request.referer)
  end

  private

  CRAWLER_WORDS = [
      'Applebot',
      'Jooblebot',
      'SBooksNet',
      'AdsBot-Google-Mobile',
      'Google-adstxt',
      'FlipboardProxy',
      'HeartRails_Capture',
      'Mail.RU_Bot',
      '360Spider',
      'Yahoo Ad monitoring',
      'KZ BRAIN Mobile',
      'Researchscan/t13rl',
      'Y!J-BRW/1.0',
      'NetcraftSurveyAgent',
      'https://',
      'http://',
      'PetalBot',
      'Seekport Crawler',
      'YandexBot',
      'ias-va/3.1',
      'ias-or/3.1',
      'ias-jp/3.1',
      'TTD-Content',
      'Barkrowler',
      'Hatena',
      'Daum/4.1',
      'TrendsmapResolver',
      'YaK/1.0',
      'Linespider',
      'PaperLiBot',
      'YandexMobileBot',
      'Yeti/1.1',
      'zgrab/0.x',
      '%E3%82%A6%E3%82%A4%E3%83%AB%E3%82%B9%E3%83%90%E3%82%B9%E3%82%BF%E3%83%BC%20for%20Mac/1', # ウイルスバスター for Mac/1
      'LightspeedSystemsCrawler',
      'Nuzzel',
      'iCoreService',
      'NetSystemsResearch',
      'DoCoMo/2.0',
      'Clipbox/2.2.5',
      'AHC/2.1',
      'admantx-ussy04/3.1',
      'Google-Apps-Script',
      'scpitspi-rs',
      'Anthill',
      'jp.loilo.LoiLoNoteSchool',
      'bingbot',
      'CriteoBot',
      'Slackbot',
      'um-LN/1.0',
  ]
  CRAWLERS_REGEXP = Regexp.union(CRAWLER_WORDS)

  CRAWLER_FULL_NAMES = [
      'WWWC/1.13',
      'Chrome',
      'Mozilla/5.0 (compatible; evc-batch/2.0)',
      'Ruby',
      'bot',
      'AWS Security Scanner',
      'Mozilla/5.0',
      'ceron.jp/1.0',
      'help@dataminr.com',
      'www.logicad.com',
      'newspaper/0.2.8',
      'Dispatch/1.2.0',
      'Mozilla/5.0 (compatible;)',
      '',
  ]
  CRAWLER_FULL_NAMES_REGEXP = Regexp.new('\A(' + CRAWLER_FULL_NAMES.map { |name| name.gsub('(', '\(').gsub(')', '\)').gsub('.', '\.') }.join('|') + ')\z')

  def from_minor_crawler?(user_agent)
    ua = user_agent.to_s
    ua.include?('Bot') || ua.match?(CRAWLERS_REGEXP) || ua.match?(CRAWLER_FULL_NAMES_REGEXP)
  end

  def maybe_bot?
    !user_signed_in? && via_dm? && %i(SymbianOS BlackBerry Linux UNKNOWN).include?(request.os)
  end

  def suspicious_user_agent?
    request.user_agent.to_s.match?(/FreeBSD|NetBSD|OpenBSD|SymbOS|SunOS/)
  end

  def suspicious_referer?
    request.referer.to_s.blank? && request.device_type == :pc
  end
end
