module HeaderHelper
  def find_header_title
    I18n.t("#{controller_name}.new.title_html", default: I18n.t('searches.common.egotter'))
  end
end
