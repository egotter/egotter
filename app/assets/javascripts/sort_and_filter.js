'use strict';

var SortAndFilter = {};

SortAndFilter.activateSortButton = function ($container, callback) {
  $container.find('.dropdown-item').on('click', function (e) {
    var $selected = $(this);
    var $button = $container.find('.dropdown-toggle');
    var $oldSelected = $container.find('.dropdown-item.active');
    $button.trigger('click');

    if ($selected.is($oldSelected)) {
      console.log('sort_order not changed');
      return false;
    }

    var value = $selected.data('sort-order');
    console.log('sort_order', value);

    $button.html($selected.text()).data('sort-order', value);
    $oldSelected.removeClass('active');
    $selected.addClass('active');

    callback({sortOrder: value});
    return false;
  });
};

SortAndFilter.activateFilterButton = function ($container, callback) {
  $container.find('.dropdown-item').on('click', function (e) {
    var $selected = $(this);
    var $button = $container.find('.dropdown-toggle');
    $button.trigger('click');

    var $checkbox = $selected.find('input');
    if ($checkbox.prop('checked')) {
      $checkbox.removeAttr('checked').prop('checked', false);
    } else {
      $checkbox.attr('checked', true).prop('checked', true);
    }

    var selectedValues = [];
    $container.find("input[type='checkbox']:checked").each(function (_, el) {
      selectedValues.push($(el).parent('a').data('filter'));
    });

    if (selectedValues.length > 0) {
      $button.find('.filter-count').text('(' + selectedValues.length + ')');
    } else {
      $button.find('.filter-count').text('');
    }

    var value = '';
    $.each(selectedValues, function (_, v) {
      value += v + ','
    });

    console.log('filter', value);
    callback({filter: value});

    return false;
  });
};

