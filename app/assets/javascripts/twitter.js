'use strict';

var Twitter = {};

Twitter.enableSortButton = function ($dropdown, afterClick) {
  $('.sort-orders').on('click', function (e) {
    var $selected = $(this);
    var $oldSelected = $dropdown.parent().find('a.selected');
    $dropdown.dropdown('toggle');

    if ($selected.is($oldSelected)) {
      console.log('sort_order not changed');
      return false;
    }
    console.log('sort_order', $selected.data('sort-order'));

    $dropdown.html($selected.text() + '&nbsp;<span class="caret"></span>')
        .data('sort-order', $selected.data('sort-order'));
    $dropdown.parent().find('.dropdown-menu a').removeClass('selected');
    $selected.addClass('selected');

    afterClick.call();
    return false;
  });
};

Twitter.enableFilterButton = function ($dropdown, afterClick) {
  $('.filters').on('click', function (e) {
    var $selected = $(this);
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

    var filterCount = $dropdown.parent().find('a.selected').length;
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
