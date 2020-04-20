'use strict';

var Twitter = {};

Twitter.cache = function () {
  var fetch = function (url, params, callback) {
    var key = JSON.stringify(params);
    var cache = $.data(document.body, key);
    if (cache) {
      console.log('response(CACHE)', cache);
      callback(cache);
      return;
    }

    $.getJSON(url, params).done(function (res) {
      console.log('response', res);
      $.data(document.body, key, res);
      callback(res);
    });
  };

  return {fetch: fetch}
};

Twitter.follow = function (url, uid, callback) {
  console.log('follow', url, uid);
  $.post(url, {uid: uid}).then(function (res) {
    console.log('res', res);
    callback.call();
  }, function (xhr) {
    if (xhr.status === 429) { // Too many requests
      $('#follow-limitation-warning-modal').modal();
    } else {
      Logger.warn(JSON.parse(xhr.responseText)['message']);
    }
  });
};

// Idempotent
Twitter.enableFollowButton = function (selector) {
  var $modal = $('#create-follow-modal');

  if (!$modal.data('init')) {
    $modal.find('.btn.ok').on('click', function () {
      var $clicked = $(this).data('btn-target');
      Twitter.follow($(this).data('url'), $clicked.data('uid'), function () {
        $clicked.hide().siblings('.btn.follow').show();
      });
      $modal.modal('hide');
    });
    $modal.data('init', true);
  }

  $(selector).off('click', '.btn.no-follow');
  $(selector).on('click', '.btn.no-follow', function (e) {
    e.stopPropagation();
    var $clicked = $(this);
    var dontConfirm = $modal.find('.dont-confirm input').prop('checked');

    if (dontConfirm) {
      Twitter.follow($modal.find('.btn.ok').data('url'), $clicked.data('uid'), function () {
        $clicked.hide().siblings('.btn.follow').show();
      });
    } else {
      $modal.find('.btn.ok').data('btn-target', $clicked);
      $modal.find('.screen-name').text($clicked.data('screen-name'));
      $modal.modal();
    }
    return false;
  });
};

Twitter.unfollow = function (url, uid, callback) {
  console.log('unfollow', url, uid);
  $.post(url, {uid: uid}).then(function (res) {
    console.log('res', res);
    callback.call();
  }, function (xhr) {
    if (xhr.status === 429) { // Too many requests
      $('#unfollow-limitation-warning-modal').modal();
    }
  });
};

// Idempotent
Twitter.enableUnfollowButton = function (selector) {
  var $modal = $('#create-unfollow-modal');

  if (!$modal.data('init')) {
    $modal.find('.btn.ok').on('click', function () {
      var $clicked = $(this).data('btn-target');
      Twitter.unfollow($(this).data('url'), $clicked.data('uid'), function () {
        $clicked.hide().siblings('.btn.no-follow').show();
      });
      $modal.modal('hide');
    });
    $modal.data('init', true);
  }


  $(selector).off('click', '.btn.follow');
  $(selector).on('click', '.btn.follow', function (e) {
    e.stopPropagation();
    var $clicked = $(this);
    var dontConfirm = $modal.find('.dont-confirm input').prop('checked');

    if (dontConfirm) {
      Twitter.unfollow($modal.find('.btn.ok').data('url'), $clicked.data('uid'), function () {
        $clicked.hide().siblings('.btn.no-follow').show();
      });
    } else {
      $modal.find('.btn.ok').data('btn-target', $clicked);
      $modal.find('.screen-name').text($clicked.data('screen-name'));
      $modal.modal();
    }
    return false;
  });
};

Twitter.FetchTask = function (url, uid, options) {
  if (this === undefined) {
    throw new TypeError();
  }

  this._url = url;
  this._uid = uid;
  this._maxSequence = 0;
  this._limit = options['limit'];
  this._minLimit = options['limit'];
  this._maxLimit = options['maxLimit'];
  this._sortOrder = options['sortOrder'];
  this._filter = options['filter'];
  this._gridClass = options['gridClass'];
  this._insertAd = options['insertAd'];
  this._loading = false;

  this._$placeholders = $('.placeholders-wrapper');
  this._$emptyPlaceholders = $('.empty-placeholders-wrapper');
  this._$usersContainer = $('.main-content.twitter.users');
};

Twitter.FetchTask.prototype = {
  constructor: Twitter.FetchTask,
  reset: function (options) {
    this._maxSequence = 0;
    this._limit = this._minLimit;
    if ('sortOrder' in options) {
      this._sortOrder = options['sortOrder'];
    }
    if ('filter' in options) {
      this._filter = options['filter'];
    }
    this._$placeholders.show();
    this._$usersContainer.empty();
    this.fetch();
  },
  fetch: function (callback) {
    if (this._maxSequence === -1) {
      return;
    }

    if (this._loading) {
      return;
    }
    this._loading = true;

    var params = {
      uid: this._uid,
      html: 1,
      limit: this._limit,
      max_sequence: this._maxSequence,
      sort_order: this._sortOrder,
      filter: this._filter,
      grid_class: this._gridClass,
      insert_ad: this._insertAd
    };

    console.log('params', params);

    var self = this;

    Twitter.cache().fetch(this._url, params, function (res) {
      if (res.max_sequence && res.max_sequence >= 0) {
        self._maxSequence = res.max_sequence + 1;
        self._limit = self._maxLimit;
      } else {
        self._maxSequence = -1;
        // $seeMoreBtn.remove();
        // $seeAtOnceBtn.remove();
      }

      self._$placeholders.hide();
      var $users = $(res.users).hide().fadeIn(1000);
      self._$usersContainer.append($users);

      if (res.users.length <= 0) {
        self._$emptyPlaceholders.show();
      } else {
        self._$emptyPlaceholders.hide();
      }

      self._loading = false;

      if (callback) {
        callback({loaded: true, completed: self._maxSequence === -1});
      }
    });
  },
  rand: function () {
    return Math.random().toString(32).substring(2);
  }
};
