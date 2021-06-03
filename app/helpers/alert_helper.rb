module AlertHelper
  def alert_box(options = {}, &block)
    category = options[:category] || 'primary'
    <<~HTML.html_safe
      <div class="text-body alert-box-#{category} p-3 #{options[:class]}">
        #{capture(&block)}
      </div>
    HTML
  end
end
