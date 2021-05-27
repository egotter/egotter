module AlertHelper
  def alert_box(options = {}, &block)
    <<~HTML.html_safe
      <div class="text-body p-3 #{options[:class]}" style="border-left: 5px solid #004085; background-color: #cce5ff;">
        #{capture(&block)}
      </div>
    HTML
  end
end
