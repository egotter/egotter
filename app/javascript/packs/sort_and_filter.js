class SortButton {
  constructor(callback) {
    var $container = $('.sort-order-container');

    $container.find('.dropdown-item').on('click', function () {
      var $selected = $(this);
      var $button = $container.find('button');
      var $oldSelected = $container.find('.dropdown-item.active');
      $button.trigger('click');

      if ($selected.is($oldSelected)) {
        logger.log('sort_order not changed');
        return false;
      }

      var value = $selected.data('sort-order');
      logger.log('sort_order', value);

      $button.html($selected.text()).data('sort-order', value);
      $oldSelected.removeClass('active');
      $selected.addClass('active');

      callback({sortOrder: value});
      return false;
    });
  }
}

window.SortButton = SortButton;

class FilterButton {
  constructor(callback) {
    var $container = $('.filter-container');

    $container.find('.dropdown-item').on('click', function () {
      var $selected = $(this);
      var $button = $container.find('button');
      $button.trigger('click');

      $selected.toggleClass('active');

      var selectedValues = [];
      $container.find(".dropdown-item.active").each(function (_, el) {
        selectedValues.push($(el).data('filter'));
      });

      if (selectedValues.length > 0) {
        $button.find('.filter-count').text('(' + selectedValues.length + ')');
      } else {
        $button.find('.filter-count').text('');
      }

      var value = selectedValues.join(',');

      logger.log('filter', value);
      callback({filter: value});

      return false;
    });
  }
}

window.FilterButton = FilterButton;
