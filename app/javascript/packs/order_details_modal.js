class OrderDetailsModal {
  constructor(id) {
    this.$el = $('#' + id);
    this.init();
  }

  init() {
    var self = this;

    this.$el.on('show.bs.modal', function (e) {
      var button = e.relatedTarget;
      self.$el.find('.order-time').html($(button).data('time'));
      self.$el.find('.order-amount').html($(button).data('amount'));
      self.$el.find('.order-search-count').html($(button).data('search-count'));
    });
  }

  show() {
    this.$el.modal();
  }
}

window.OrderDetailsModal = OrderDetailsModal;
