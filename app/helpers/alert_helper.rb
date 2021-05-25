module AlertHelper
  def alert_box(&block)
    <<~HTML.html_safe
      <div class="text-body p-3" style="border-left: 5px solid #004085; background-color: #cce5ff;">
        #{capture(&block)}
      </div>
    HTML
  end
end
