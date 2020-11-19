class SortButton {
  constructor(callback) {
    this.callback = callback;
    this.$container = $('.sort-order-container');
    var self = this;

    this.$container.find('.dropdown-item').not('.btn-checkout').not('.btn-end-trial').on('click', function () {
      return self.clickItem($(this));
    });
  }

  clickItem($selected) {
    var $button = this.$container.find('button');
    var $oldSelected = this.$container.find('.dropdown-item.active');
    $button.trigger('click'); // Close dropdown menu

    if ($selected.is($oldSelected)) {
      logger.log('sort_order not changed');
      return false;
    }

    var value = $selected.data('sort-order');
    logger.log('sort_order', value);

    this.updateView($button, $oldSelected, $selected, $selected.text());
    this.callback({sortOrder: value});

    return false;
  }

  updateView(button, oldSelected, selected, label) {
    button.find('.label').html(label);
    oldSelected.removeClass('active');
    selected.addClass('active');
  }
}

window.SortButton = SortButton;

class FilterButton {
  constructor(callback) {
    this.callback = callback;
    this.$container = $('.filter-container');
    var self = this;

    this.$container.find('.dropdown-item').not('.btn-checkout').not('.btn-end-trial').on('click', function () {
      return self.clickItem($(this));
    });
  }

  clickItem($selected) {
    var $button = this.$container.find('button');
    $button.trigger('click');

    $selected.toggleClass('active');

    var selectedValues = [];
    this.$container.find(".dropdown-item.active").each(function (_, el) {
      selectedValues.push($(el).data('filter'));
    });

    if (selectedValues.length > 0) {
      $button.find('.filter-count').text('(' + selectedValues.length + ')');
    } else {
      $button.find('.filter-count').text('');
    }

    var value = selectedValues.join(',');

    logger.log('filter', value);
    this.callback({filter: value});

    return false;
  }
}

window.FilterButton = FilterButton;
