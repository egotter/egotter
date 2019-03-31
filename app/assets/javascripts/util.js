'use strict';

var Util = {};

Util.alert = function (text) {
  console.log(text);
  $('.ajax-alert-container').find('p').html(text).end().show();
};
