'use strict';

var Welcome = {};

class ModalDialog {
  constructor($el) {
    this.$el = $el;
    this.cache_key = $el.attr('id');
    this.cache = window['sessionStorage'] || {};
  }

  show(force) {
    if (force) {
      this.$el.modal();
    } else {
      if (!this.cache[this.cache_key]) {
        console.log('show', this.$el);
        this.cache[this.cache_key] = true;
        this.$el.modal('show');
      } else {
        console.log('already shown', this.$el);
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

    $el.find('button.positive').on('click', function () {
      var tweet = $el.find('textarea').val();
      var url = $el.data('url');

      $.post(url, {text: tweet}).done(function (res) {
        console.log(url, res);
        SnackMessage.success($el.data('success-message'));

      }).fail(function (xhr) {
        var reason = $el.data('error-message');
        if (xhr.status === 400 && xhr.responseText && JSON.parse(xhr.responseText)['reason']) {
          reason = JSON.parse(xhr.responseText)['reason'];
        }
        SnackMessage.alert(reason);
      });

      $el.modal('hide');
    });
  }
}

Welcome.ShareDialog = ShareDialog;

class FollowDialog extends ModalDialog {
  constructor() {
    super($('#follow-modal'));

    var $el = this.$el;

    $el.find('button.positive').on('click', function () {
      window.open($el.data('follow-url'), '_blank');

      $.post($el.data('url'), {uid: $el.data('uid')}, function (res) {
        console.log('FollowDialog', res);
      });

      $el.modal('hide');
    });
  }
}

class ReviveDialog extends ModalDialog {
  constructor() {
    super($('#revive-modal'));

    var $el = this.$el;
    var url = $el.data('url');

    $el.find('button.positive').on('click', function () {
      window.open(url, '_blank');
      $el.modal('hide');
    });
  }
}

class Util {
  static showShareDialog() {
    return this.getParameterByName('share_dialog') === '1';
  }

  static showFollowDialog() {
    return this.getParameterByName('follow_dialog') === '1';
  }

  static showReviveDialog() {
    return this.getParameterByName('revive_dialog') === '1';
  }

  static getParameterByName(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[[\]]/g, '\\$&');
    var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, ' '));
  }
}

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

Welcome.showFollowDialogAndShareDialog = function (followingEgotter) {
  var queue = new ModalQueue();

  if (Util.showReviveDialog()) {
    queue.add(new ReviveDialog());
  }

  if (Util.showFollowDialog() && !followingEgotter) {
    queue.add(new FollowDialog());
  }

  if (Util.showShareDialog()) {
    queue.add(new ShareDialog());
  }

  queue.start();
};

window.Welcome = Welcome;
