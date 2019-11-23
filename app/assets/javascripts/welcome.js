'use strict';

$(function () {
  function getParameterByName(name, url) {
    if (!url) url = window.location.href;
    name = name.replace(/[\[\]]/g, '\\$&');
    var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
        results = regex.exec(url);
    if (!results) return null;
    if (!results[2]) return '';
    return decodeURIComponent(results[2].replace(/\+/g, ' '));
  }

  var $follow = $('#follow-modal');
  var $share = $('#share-modal');
  var cache = window['sessionStorage'] || {};

  if (getParameterByName('follow_dialog') === '1' && getParameterByName('share_dialog') === '1') {
    $follow.on('hidden.bs.modal', function (e) {
      if (!cache['share_dialog']) {
        cache['share_dialog'] = true;
        $share.modal();
      }
    });
    if (!cache['follow_dialog']) {
      cache['follow_dialog'] = true;
      $follow.modal();
    }
  } else if (getParameterByName('follow_dialog') === '1') {
    if (!cache['follow_dialog']) {
      cache['follow_dialog'] = true;
      $follow.modal();
    }
  } else if (getParameterByName('share_dialog') === '1') {
    if (!cache['share_dialog']) {
      cache['share_dialog'] = true;
      $share.modal();
    }
  }

  $follow.find('button.ok').on('click', function () {
    var $clicked = $(this);
    window.open($clicked.data('follow-url'), '_blank');

    $.post($clicked.data('url'), {uid: $clicked.data('uid')}, function (res) {
      console.log('createFollow', res);
    });

    $follow.modal('hide');
  });

  $share.find('button.ok').on('click', function () {
    $.post($(this).data('url'), {text: $('#share-modal').find('textarea').val()}, function (res) {
      console.log('createShare', res);
      if (window.location.pathname.startsWith('/settings')) {
        window.location.reload();
      }
    });

    $share.modal('hide');
  });
});