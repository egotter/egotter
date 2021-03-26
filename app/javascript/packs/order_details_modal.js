class OrderDetailsModal {
  constructor(id) {
    this.$el = $('#' + id);
    this.init();
  }

  init() {
    var self = this;

    this.$el.on('show.bs.modal', function (e) {
      var button = e.relatedTarget;
      self.$el.find('.order-amount').html($(button).data('amount'));
      self.$el.find('.order-search-count').html($(button).data('search-count'));
      self.$el.find('.order-created-at').html($(button).data('created-at'));
      self.$el.find('.order-canceled-at').html($(button).data('canceled-at'));
      self.$el.find('.order-charge-failed-at').html($(button).data('charge-failed-at'));
    });
  }

  show() {
    this.$el.modal();
  }
}

window.OrderDetailsModal = OrderDetailsModal;
