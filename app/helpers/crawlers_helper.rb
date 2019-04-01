module CrawlersHelper
  def reject_crawler
    head :forbidden if from_crawler?
  end

  def from_crawler?
    request.from_crawler? || !!from_minor_crawler?(request.user_agent)
  end

  private

  CRAWLERS_REGEXP = /Applebot|Jooblebot|SBooksNet|AdsBot-Google-Mobile|FlipboardProxy|HeartRails_Capture|Mail\.RU_Bot|360Spider/

  def from_minor_crawler?(user_agent)
    user_agent.to_s.match? CRAWLERS_REGEXP
  end

  def maybe_bot?
    !user_signed_in? && via_dm? && %i(SymbianOS BlackBerry Linux UNKNOWN).include?(request.os)
  end
end
