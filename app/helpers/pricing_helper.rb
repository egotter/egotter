module PricingHelper
  def pricing_checked_item(text)
    tag.i(class: 'fas fa-check text-primary') + '&nbsp;'.html_safe + text
  end

  def pricing_unchecked_item(text)
    tag.i(class: 'fas fa-times text-danger') + '&nbsp;'.html_safe + text
  end
end
