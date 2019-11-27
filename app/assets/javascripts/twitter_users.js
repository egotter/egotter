'use strict';

var TwitterUsers = {};

TwitterUsers.requestToCreateTwitterUser = function (url, uid, done, fail) {
  $.post(url, {uid: uid}).done(done).fail(fail);
};

TwitterUsers.isFollowingEgotter = function (url, callback) {
  $.getJSON(url, function (res) {
    console.log('isFollowingEgotter', res);
    callback(res);
  });
};

TwitterUsers.detectSecretMode = function () {
  var fs = window.RequestFileSystem || window.webkitRequestFileSystem;
  if (fs) {
    fs(window.TEMPORARY,
        100,
        function (fs) {
        },
        function (fe) {
          ga('send', {
            hitType: 'event',
            eventCategory: 'SecretMode',
            eventAction: 'found',
            eventLabel: 'found'
          });
        });
  }
}

