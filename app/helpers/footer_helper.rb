module FooterHelper
  def footer_item(&block)
    <<~HTML.html_safe
      <li class="list-inline-item d-none d-md-inline-block">⋅</li>
      <li class="list-inline-item mb-3">#{capture(&block)}</li>
      <br class="d-block d-md-none">
    HTML
  end
end
