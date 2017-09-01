module CrawlersHelper
  def reject_crawler
    if from_crawler?
      render text: t('before_sign_in.reject_crawler')
    end
  end

  def from_crawler?
    request.from_crawler? || !!from_minor_crawler?(request.user_agent)
  end

  def from_minor_crawler?(user_agent)
    user_agent.to_s.match /Applebot|Jooblebot|SBooksNet|AdsBot-Google-Mobile|FlipboardProxy|HeartRails_Capture|Mail\.RU_Bot|360Spider/
  end
end
