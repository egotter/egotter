class ToastMessage {
  static ids = [];

  static show(message, options = {}) {
    var id = Math.random().toString(32).substring(10);
    var opt = Object.assign({
      id: id,
      title: 'Notification',
      body: message,
      time: this.currentTime(),
      autohide: true,
      delay: 30000,
      animation: false
    }, options);

    if (options['warn']) {
      opt['body'] = '<div class="text-danger">' + opt['body'] + '</div>';
    }

    var template = window.templates['toast'];
    var rendered = Mustache.render(template, opt);
    console.log('ToastMessage', opt);

    this.ids.forEach(function (val) {
      $('#' + val).toast('hide');
    });

    var toast = $(rendered).toast(opt);
    $('#toast-container').append(toast);

    setTimeout(function () {
      $('#' + id).toast('show');
    }, 500);

    this.ids.push(id);

    return id;
  }

  static info(message, options) {
    this.show(message, options);
  }

  static warn(message, options = {}) {
    options['warn'] = true;
    this.show(message, options);
  }

  static clear() {
    this.ids.forEach(function (val) {
      $('#' + val).toast('hide');
    });
  }

  static currentTime() {
    var t = new Date();
    return t.getHours() + ':' + t.getMinutes();
  }
}

window.ToastMessage = ToastMessage;
