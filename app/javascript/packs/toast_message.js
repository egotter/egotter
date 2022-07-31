// Bootstrap's Toasts
class ToastMessage {
  static ids = [];

  static show(message, options) {
    if (this.freezed) {
      return;
    }

    var opt = Object.assign({
      title: 'Notification',
      body: message,
      time: this.currentTime(),
      autohide: true,
      delay: 60000,
      animation: true,
      ttl: 300
    }, options);

    if (opt['id']) {
      opt['id'] = 'toast-' + opt['id'];
    } else {
      opt['id'] = 'toast-' + Math.random().toString(32).substring(10);
    }

    if (this.isAlreadyShown(opt['id'], opt['ttl'])) {
      return;
    }

    if (options['warn']) {
      opt['body'] = '<div class="text-danger">' + opt['body'] + '</div>';
    }

    var template = window.templates['toast'];
    var rendered = Mustache.render(template, opt);
    logger.log('Toast message', opt);

    this.clear();

    var toast = $(rendered).toast(opt);
    $('#toast-container').append(toast);

    $('#' + opt['id']).toast('show');
    // setTimeout(function () {
    //   $('#' + opt['id']).toast('show');
    // }, 500);

    $('#' + opt['id']).on('hidden.bs.toast', function () {
      logger.log('Toast hidden', opt['id']);
    });

    this.ids.push(opt['id']);

    return opt['id'];
  }

  static info(message, options = {}) {
    return this.show(message, options);
  }

  static warn(message, options = {}) {
    options['warn'] = true;
    return this.show(message, options);
  }

  static isAlreadyShown(id, ttl) {
    var cache = new Egotter.Cache(ttl);
    var key = id + '-' + ttl;

    if (cache.read(key)) {
      logger.log('Toast already shown', key);
      return true;
    } else {
      cache.write(key, true);
      return false;
    }
  }

  static freeze() {
    this.freezed = true;
  }

  static hide(id) {
    $('#' + id).toast('hide');
  }

  static clear() {
    this.ids.forEach(function (val) {
      $('#' + val).toast('hide');
    });
  }

  static currentTime() {
    var t = new Date();
    var hour = ('' + t.getHours()).padStart(2, '0');
    var min = ('' + t.getMinutes()).padStart(2, '0');
    return hour + ':' + min;
  }
}

window.ToastMessage = ToastMessage;
