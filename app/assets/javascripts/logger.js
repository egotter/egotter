'use strict';

var Logger = {};

Logger.warn = function (text) {
  console.log(text);
  $('#ajax-warning-message').find('p').html(text).end().show();
};
