module CampaignsHelper
  def campaign_params(name, medium = 'dm')
    {
        via: name,
        utm_source: name,
        utm_medium: medium,
        utm_campaign: "#{name}_#{I18n.l(Time.zone.now, format: :date_hyphen)}",
    }
  end
end
