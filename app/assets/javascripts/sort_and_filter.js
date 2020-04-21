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

    $selected.toggleClass('active')

    var selectedValues = [];
    $container.find(".dropdown-item.active").each(function (_, el) {
      selectedValues.push($(el).data('filter'));
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

