module FeedsHelper
  def feed_item(category, options)
    render partial: "timelines/feeds/#{category}", locals: options
  end
end
