var Welcome = {};

class ModalDialog {
  constructor($el) {
    this.$el = $el;
    this.cache_key = $el.attr('id') + '-' + moment().format("YYYYMMDD");
    this.cache = new Egotter.Cache();
  }

  show(force) {
    if (force) {
      this.$el.modal();
    } else {
      if (this.cache.read(this.cache_key)) {
        logger.log('already shown', this.$el, this.cache_key, this.cache.remaining(this.cache_key));
      } else {
        logger.log('show', this.$el, this.cache_key, this.cache.remaining(this.cache_key));
        this.cache.write(this.cache_key, true);
        this.$el.modal('show');
      }
    }
  }

  on(event, fn) {
    this.$el.on(event, fn);
  }
}

class ShareDialog extends ModalDialog {
  constructor() {
    super($('#share-modal'));

    var $el = this.$el;

    if ($el.data('initialized')) {
      return;
    }
    $el.data('initialized', true);

    $el.find('button.positive').on('click', function () {
      var tweet = $el.find('textarea').val();
      var url = $el.data('url');

      $.post(url, {text: tweet}).done(function (res) {
        logger.log(url, res);
        ToastMessage.info($el.data('success-message'));

      }).fail(function (xhr) {
        var reason = $el.data('error-message');
        if (xhr.status === 400 && xhr.responseText && JSON.parse(xhr.responseText)['reason']) {
          reason = JSON.parse(xhr.responseText)['reason'];
        }
        ToastMessage.warn(reason);
      });

      $el.modal('hide');
    });
  }
}

window.ShareDialog = ShareDialog;

class TweetTextUpdater {
  constructor(tweets, textAreaSelector) {
    var index = 0;
    this.updateText = function () {
      ++index;
      if (index >= tweets.length) {
        index = 0;
      }
      $(textAreaSelector).val(tweets[index].replace(/\\n/g, '\n'));
    };
  }

  update(callback) {
    this.updateText();
    callback();
  }
}

ShareDialog.TweetTextUpdater = TweetTextUpdater;

class PeriodicTweetDialog extends ModalDialog {
  constructor() {
    super($('#periodic-tweet-modal'));

    var $el = this.$el;

    if ($el.data('initialized')) {
      return;
    }
    $el.data('initialized', true);

    $el.find('button.positive').on('click', function () {
      var url = $el.data('url');

      $.post(url, {value: true}).done(function (res) {
        logger.log(url, res);
        ToastMessage.info($el.data('success-message'));

      }).fail(function (xhr) {
        logger.warn(url, xhr.responseText);
        ToastMessage.warn($el.data('error-message'));
      });

      $el.modal('hide');
    });
  }
}

Welcome.PeriodicTweetDialog = PeriodicTweetDialog;

class ContinuousSignInDialog extends ModalDialog {
  constructor() {
    super($('#continuous-sign-in-modal'));
  }
}

window.ContinuousSignInDialog = ContinuousSignInDialog;

class FollowDialog extends ModalDialog {
  constructor() {
    super($('#follow-modal'));

    var $el = this.$el;

    $el.find('button.positive').on('click', function () {
      window.open($el.data('follow-url'), '_blank');

      $.post($el.data('url'), {uid: $el.data('uid')}, function (res) {
        logger.log('FollowDialog', res);
      });

      $el.modal('hide');
    });
  }
}

window.FollowDialog = FollowDialog;

class PurchaseDialog extends ModalDialog {
  constructor(url) {
    super($('#purchase-modal'));
    var $el = this.$el;

    $el.find('.btn.positive').on('click', function () {
      window.open(url, '_blank');
    });
  }
}

window.PurchaseDialog = PurchaseDialog;

class SignInDialog {
  constructor(id, url) {
    var $el = $('#' + id);

    $el.find('.btn.positive').on('click', function () {
      window.location.href = url;
    });

    $el.modal();
  }
}

// class Util {
//   static showShareDialog() {
//     return this.getParameterByName('share_dialog') === '1';
//   }
//
//   static showFollowDialog() {
//     return this.getParameterByName('follow_dialog') === '1';
//   }
//
//   static showSignInDialog() {
//     return this.getParameterByName('sign_in_dialog') === '1';
//   }
//
//   static getParameterByName(name, url) {
//     if (!url) url = window.location.href;
//     name = name.replace(/[[\]]/g, '\\$&');
//     var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
//         results = regex.exec(url);
//     if (!results) return null;
//     if (!results[2]) return '';
//     return decodeURIComponent(results[2].replace(/\+/g, ' '));
//   }
// }

class ModalQueue {
  constructor() {
    this.ary = [];
  }

  add($el) {
    var ary = this.ary;
    ary.push($el);
    var self = this;

    $el.on('hidden.bs.modal', function () {
      self.next();
    });
  }

  start() {
    if (this.ary.length >= 1) {
      this.ary.pop().show();
    }
  }

  next() {
    this.start();
  }
}

window.ModalQueue = ModalQueue;

Welcome.showSignInDialog = function (id, url) {
  var queue = new ModalQueue();

  queue.add(new SignInDialog(id, url));
  // if (Util.showSignInDialog()) {
  //   queue.add(new SignInDialog(id, url));
  // }

  queue.start();
};

window.Welcome = Welcome;
