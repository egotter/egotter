'use strict';

var TwitterUsers = {};

TwitterUsers.AlertBox = function (requestToUpdate, nextCreationTimeMessage, twitterUser, eventCategory) {
  if (this === undefined) {
    throw new TypeError();
  }

  this._boxes = {
    update: $('#update-box'),
    updateThisPage: $('#update-this-page-box'),
    requestToUpdate: $('#request-to-update-box'),
    failed: $('#failed-box'),
    refresh: $('#refresh-box'),
    tooManyFriends: $('#too-many-friends-box'),
    follow: $('#follow-box'),
    justFollowed: $('#just-followed-box'),
    notFollowed: $('#not-followed-box'),
    invalidToken: $('#invalid-token-box'),
    accurateCounting: $('#accurate-counting-box'),
    viaDM: $('#via-dm-box'),
    signIn: $('#sign-in-box'),
    tooManySearches: $('#too-many-searches-box')
  };

  this._shown = null;
  this._eventCategory = eventCategory;
  this._twitterUser = twitterUser;

  if (requestToUpdate) {
    console.log('Switch to request');
    this._boxes['updateThisPage'] = this._boxes['requestToUpdate'];
  }
  console.log(nextCreationTimeMessage);
  this._boxes['updateThisPage'].find('.next-creation-note').html(nextCreationTimeMessage);

  $('.sticky-box').each(function (i, box) {
    var $box = $(box);

    // $box.on('close.bs.alert', function () {
    //   $box.parent('.sticky-wrapper').hide();
    // });

    $box.find('a').on('click', function (e) {
      ga('send', {
        hitType: 'event',
        eventCategory: eventCategory,
        eventAction: $box.data('name') + ' clicked',
        eventLabel: JSON.stringify($.extend({href: e.target.href}, twitterUser)),
        transport: 'beacon'
      });
    });
  });
};

TwitterUsers.AlertBox.prototype = {
  constructor: TwitterUsers.AlertBox,
  find: function (name) {
    return this._boxes[name];
  },
  show: function (name) {
    var $box = this._boxes[name];
    console.log('show', $box);

    if ($box) {
      if (this._shown) {
        this._shown.hide().unstick();
        this._shown = null;
      }
      $box.show().sticky();
      this._shown = $box;

      ga('send', {
        hitType: 'event',
        eventCategory: this._eventCategory,
        eventAction: $box.data('name') + ' shown',
        eventLabel: JSON.stringify(this._twitterUser),
        transport: 'beacon'
      });
    }
  }
};

TwitterUsers.sneakLogger = {
  warn: function () {
    var args = Array.from(arguments);
    var text = args.join(' ');
    $('#global-sneak-error-message').text(text);
  }
};

TwitterUsers.requestToCreateTwitterUser = function (url, params, done, fail) {
  $.post(url, params).done(done).fail(fail);
};

TwitterUsers.isFollowingEgotter = function (url, callback) {
  $.getJSON(url, function (res) {
    console.log('isFollowingEgotter', res);
    callback(res);
  });
};

TwitterUsers.confirmAccountStatus = function (url, done, fail) {
  $.get(url).done(done).fail(fail);
};
