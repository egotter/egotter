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

Twitter.follow = function (url, uid) {
  console.log('follow', url, uid);
  $.post(url, {uid: uid}, function (res) {
    console.log('res', res);
    if (!res.can_create_follow) {
      console.log('warning', res.create_follow_limit);
    }
  });
};

Twitter.enableFollowButton = function (selector) {
  var $modal = $('#create-follow-modal');

  if (!$modal.data('init')) {
    $modal.find('.btn.ok').on('click', function () {
      var $clicked = $(this).data('btn-target');
      Twitter.follow($(this).data('url'), $clicked.data('uid'));
      $clicked.hide()
          .siblings('.btn.follow').show();
      $modal.modal('hide');
    });
    $modal.data('init', true);
  }

  $(selector).on('click', '.btn.no-follow', function () {
    var $clicked = $(this);
    if ($modal.find('.dont-confirm input').prop('checked')) {
      Twitter.follow($modal.find('.btn.ok').data('url'), $clicked.data('uid'));
      $clicked.hide()
          .siblings('.btn.follow').show();
    } else {
      $modal.find('.btn.ok').data('btn-target', $clicked);
      $modal.find('.screen-name').text($clicked.data('screen-name'));
      $modal.modal();
    }
    return false;
  });
};

Twitter.unfollow = function (url, uid) {
  console.log('unfollow', url, uid);
  $.post(url, {uid: uid}, function (res) {
    console.log('res', res);
    if (!res.can_create_unfollow) {
      console.log('warning', res.create_unfollow_limit);
    }
  });
};

Twitter.enableUnfollowButton = function (selector) {
  var $modal = $('#create-unfollow-modal');

  if (!$modal.data('init')) {
    $modal.find('.btn.ok').on('click', function () {
      var $clicked = $(this).data('btn-target');
      Twitter.unfollow($(this).data('url'), $clicked.data('uid'));
      $clicked.hide()
          .siblings('.btn.no-follow').show();
      $modal.modal('hide');
    });
    $modal.data('init', true);
  }


  $(selector).on('click', '.btn.follow', function () {
    var $clicked = $(this);
    if ($modal.find('.dont-confirm input').prop('checked')) {
      Twitter.unfollow($modal.find('.btn.ok').data('url'), $clicked.data('uid'));
      $clicked.hide()
          .siblings('.btn.no-follow').show();
    } else {
      $modal.find('.btn.ok').data('btn-target', $clicked);
      $modal.find('.screen-name').text($clicked.data('screen-name'));
      $modal.modal();
    }
    return false;
  });
};

Twitter.enableSortButton = function ($buttons, afterClick) {
  $('.sort-orders').on('click', function (e) {
    var $selected = $(this);
    var $dropdown = $buttons.find('.dropdown-toggle');
    var $oldSelected = $buttons.find('a.selected');
    $dropdown.dropdown('toggle');

    if ($selected.is($oldSelected)) {
      console.log('sort_order not changed');
      return false;
    }
    console.log('sort_order', $selected.data('sort-order'));

    $dropdown.html($selected.text() + '&nbsp;<span class="caret"></span>')
        .data('sort-order', $selected.data('sort-order'));
    $buttons.find('.dropdown-menu a').removeClass('selected');
    $selected.addClass('selected');

    afterClick.call();
    return false;
  });
};

Twitter.enableFilterButton = function ($buttons, afterClick) {
  $('.filters').on('click', function (e) {
    var $selected = $(this);
    var $dropdown = $buttons.find('.dropdown-toggle');
    console.log('filter', $selected.data('filter'));

    $dropdown.dropdown('toggle');

    var $checkbox = $selected.find('input');
    if ($checkbox.prop('checked')) {
      $checkbox.removeAttr('checked').prop('checked', false);
      $selected.removeClass('selected');
    } else {
      $checkbox.attr('checked', true).prop('checked', true);
      $selected.addClass('selected');
    }

    var filterCount = $buttons.find('a.selected').length;
    if (filterCount > 0) {
      $dropdown.data('filter', $selected.data('filter')); // Current filters.size == 0
      $dropdown.find('.filter-count').text('(' + filterCount + ')');
    } else {
      $dropdown.data('filter', null);
      $dropdown.find('.filter-count').text('');
    }

    afterClick.call();
    return false;
  });
};
