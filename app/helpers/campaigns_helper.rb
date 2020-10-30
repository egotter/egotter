module CampaignsHelper
  def campaign_params(name, medium = 'dm')
    {
        via: name,
        utm_source: name,
        utm_medium: medium,
        utm_campaign: name,
    }
  end

  def dialog_params
    {
        follow_dialog: 1,
        sign_in_dialog: 1,
        share_dialog: 1,
        purchase_dialog: 1
    }
  end
end
