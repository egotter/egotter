class MustacheUtil {
  static renderUser(template, user) {
    var self = this;
    var rendered = $(Mustache.render(template, user));

    if (user.profile_image_url) {
      rendered.find('img').on('error', function () {
        self.drawFallbackTextToImage(rendered.find('img'));
        return true;
      }).attr('src', user.profile_image_url);
    } else {
      self.drawFallbackTextToImage(rendered.find('img'));
    }

    return rendered;
  }

  static drawFallbackTextToImage(img) {
    this.drawText(img.parent(), img.attr('alt'));
    img.remove();
  }

  static drawText(container, text) {
    var style = 'font-size: x-small; width: 48px; height: 48px; overflow: hidden;';
    var div = $('<div/>', {text: text, class: 'rounded shadow p-1', style: style});
    container.append(div);
  }
}

window.MustacheUtil = MustacheUtil;
