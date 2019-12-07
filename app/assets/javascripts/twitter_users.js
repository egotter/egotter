'use strict';

var TwitterUsers = {};

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
