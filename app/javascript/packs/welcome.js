'use strict';

var Welcome = {};

class ShareDialog {
  constructor() {
    this.$el = $('#share-modal');
    this.cache_key = 'share_dialog';
    this.cache = window['sessionStorage'] || {};

    var $el = this.$el;

    $el.find('button.positive').on('click', function () {
      var tweet = $el.find('textarea').val();

      $.post($el.data('url'), {text: tweet}).done(function (res) {
        console.log('ShareDialog', res);
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

  show(force) {
    if (force) {
      this.$el.modal();
    } else {
      if (!this.cache[this.cache_key]) {
        console.log('show share-dialog', this.$el);
        this.cache[this.cache_key] = true;
        this.$el.modal('show');
      } else {
        console.log('share-dialog is already shown');
      }
    }
  }

  on(event, fn) {
    this.$el.on(event, fn);
  }
}

Welcome.ShareDialog = ShareDialog;

class FollowDialog {
  constructor() {
    this.$el = $('#follow-modal');
    this.cache_key = 'follow_dialog';
    this.cache = window['sessionStorage'] || {};

    var $el = this.$el;

    $el.find('button.positive').on('click', function () {
      window.open($el.data('follow-url'), '_blank');

      $.post($el.data('url'), {uid: $el.data('uid')}, function (res) {
        console.log('FollowDialog', res);
      });

      $el.modal('hide');
    });
  }

  show() {
    if (!this.cache[this.cache_key]) {
      console.log('show follow-dialog', this.$el);
      this.cache[this.cache_key] = true;
      this.$el.modal();
    } else {
      console.log('follow-dialog is already shown');
    }
  }
}

class ReviveDialog {
  constructor() {
    this.$el = $('#revive-modal');
    var $el = this.$el;
    var url = $el.data('url');

    $el.find('button.positive').on('click', function () {
      window.open(url, '_blank');
      $el.modal('hide');
    });
  }

  show() {
    this.$el.modal();
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

Welcome.showFollowDialogAndShareDialog = function (followingEgotter) {
  var shareDialog = new ShareDialog();
  var followDialog = new FollowDialog();

  if (Util.showReviveDialog()) {
    new ReviveDialog().show();
  } else {
    if (Util.showFollowDialog() && Util.showShareDialog()) {
      shareDialog.on('hidden.bs.modal', function hidden() {
        if (!followingEgotter) {
          followDialog.show();
        }
      });
      shareDialog.show();
    } else if (Util.getParameterByName('follow_dialog') === '1') {
      if (!followingEgotter) {
        followDialog.show();
      }
    } else if (Util.getParameterByName('share_dialog') === '1') {
      shareDialog.show();
    }
  }
};

window.Welcome = Welcome;
