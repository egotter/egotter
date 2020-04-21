'use strict';

var Welcome = {};

Welcome.ShareDialog = function () {
  if (this === undefined) {
    throw new TypeError();
  }

  this._modal = $('#share-modal');
  this._cache = window['sessionStorage'] || {};

  var modal = this._modal;

  modal.find('button.positive').on('click', function () {
    var tweet = modal.find('textarea').val();

    $.post(modal.data('url'), {text: tweet}).done(function (res) {
      SnackMessage.success(modal.data('success-message'));

      // if (window.location.pathname.startsWith('/settings')) {
      //   window.location.reload();
      // }
    }).fail(function (xhr) {
      var reason = modal.data('error-message');
      if (xhr.status === 400 && xhr.responseText && JSON.parse(xhr.responseText)['reason']) {
        reason = JSON.parse(xhr.responseText)['reason'];
      }
      SnackMessage.alert(reason);
    });

    modal.modal('hide');
  });
};

Welcome.ShareDialog.prototype = {
  constructor: Welcome.ShareDialog,
  show: function (force) {
    if (force) {
      this._modal.modal();
    } else {
      if (!this._cache['share_dialog']) {
        console.log('show share-dialog', this._modal);
        this._cache['share_dialog'] = true;
        this._modal.modal('show');
      } else {
        console.log('share-dialog is already shown');
      }
    }
  },
  on: function (event, fn) {
    this._modal.on(event, fn);
  }
};

Welcome.FollowDialog = function () {
  if (this === undefined) {
    throw new TypeError();
  }

  this._modal = $('#follow-modal');
  this._cache = window['sessionStorage'] || {};

  var modal = this._modal;

  modal.find('button.positive').on('click', function () {
    window.open(modal.data('follow-url'), '_blank');

    $.post(modal.data('url'), {uid: modal.data('uid')}, function (res) {
      console.log('createFollow', res);
    });

    modal.modal('hide');
  });
};

Welcome.FollowDialog.prototype = {
  constructor: Welcome.FollowDialog,
  show: function () {
    if (!this._cache['follow_dialog']) {
      console.log('show follow-dialog', this._modal);
      this._cache['follow_dialog'] = true;
      this._modal.modal();
    } else {
      console.log('follow-dialog is already shown');
    }
  },
  on: function (event, fn) {
    this._modal.on(event, fn);
  }
};

Welcome.ReviveDialog = function () {
  if (this === undefined) {
    throw new TypeError();
  }

  this._modal = $('#revive-modal');
  var modal = this._modal;
  var url = modal.data('url');

  modal.find('button.positive').on('click', function () {
    window.open(url, '_blank');
    modal.modal('hide');
  });
};

Welcome.ReviveDialog.prototype = {
  constructor: Welcome.ReviveDialog,
  show: function () {
    this._modal.modal();
  },
  on: function (event, fn) {
    this._modal.on(event, fn);
  }
};

Welcome.getParameterByName = function (name, url) {
  if (!url) url = window.location.href;
  name = name.replace(/[\[\]]/g, '\\$&');
  var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
      results = regex.exec(url);
  if (!results) return null;
  if (!results[2]) return '';
  return decodeURIComponent(results[2].replace(/\+/g, ' '));
};

Welcome.showFollowDialogAndShareDialog = function (followingEgotter) {
  var shareDialog = new Welcome.ShareDialog();
  var followDialog = new Welcome.FollowDialog();
  var reviveDialog = new Welcome.ReviveDialog();

  if (Welcome.getParameterByName('revive_dialog') === '1') {
    reviveDialog.show();
  } else {
    if (Welcome.getParameterByName('follow_dialog') === '1' && Welcome.getParameterByName('share_dialog') === '1') {
      shareDialog.on('hidden.bs.modal', function (e) {
        if (!followingEgotter) {
          followDialog.show();
        }
      });
      shareDialog.show();
    } else if (Welcome.getParameterByName('follow_dialog') === '1') {
      if (!followingEgotter) {
        followDialog.show();
      }
    } else if (Welcome.getParameterByName('share_dialog') === '1') {
      shareDialog.show();
    }
  }
};
