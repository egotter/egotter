module CampaignsHelper
  def campaign_params(name, medium = 'dm')
    {
        via: name,
        utm_source: name,
        utm_medium: medium,
        utm_campaign: name,
    }
  end
end
