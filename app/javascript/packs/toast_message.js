class ToastMessage {
  static ids = [];

  static show(message, options) {
    var opt = Object.assign({
      title: 'Notification',
      body: message,
      time: this.currentTime(),
      autohide: true,
      delay: 30000,
      animation: false
    }, options);

    if (!opt['id']) {
      opt['id'] = Math.random().toString(32).substring(10);
    }

    if (this.isAlreadyShown(opt['id'])) {
      return;
    }

    if (options['warn']) {
      opt['body'] = '<div class="text-danger">' + opt['body'] + '</div>';
    }

    var template = window.templates['toast'];
    var rendered = Mustache.render(template, opt);
    console.log('Toast message', opt);

    this.ids.forEach(function (val) {
      $('#' + val).toast('hide');
    });

    var toast = $(rendered).toast(opt);
    $('#toast-container').append(toast);

    setTimeout(function () {
      $('#' + opt['id']).toast('show');
    }, 500);

    $('#' + opt['id']).on('hidden.bs.toast', function () {
      console.log('Toast hidden', opt['id']);
    });

    this.ids.push(opt['id']);

    return opt['id'];
  }

  static info(message, options = {}) {
    this.show(message, options);
  }

  static warn(message, options = {}) {
    options['warn'] = true;
    this.show(message, options);
  }

  static isAlreadyShown(id) {
    var ttl = 300;
    var cache = new Egotter.Cache(ttl);
    var key = id + '-' + ttl;

    if (cache.read(key)) {
      console.log('Toast already shown', key);
      return true;
    } else {
      cache.write(key, true);
      return false;
    }
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
