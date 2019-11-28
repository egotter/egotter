module SharesHelper
  def egotter_share_text(shorten_url: false, via: nil, without_url: false)
    if without_url
      t('shares.create.text_without_url', kaomoji: Kaomoji.happy, url: egotter_share_url(shorten_url: shorten_url, via: via))
    else
      t('shares.create.text', kaomoji: Kaomoji.happy, url: egotter_share_url(shorten_url: shorten_url, via: via))
    end
  end

  def egotter_share_url(shorten_url: false, via: nil)
    via = "share#{l(Time.zone.now.in_time_zone('Tokyo'), format: :share_text_short)}" unless via
    url = root_url(via: via)
    Util::UrlShortener.shorten(url) if shorten_url
    url
  end
end
