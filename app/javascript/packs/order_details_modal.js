class OrderDetailsModal {
  constructor(id) {
    this.$el = $('#' + id);
    this.init();
  }

  init() {
    var self = this;

    this.$el.on('show.bs.modal', function (e) {
      var button = e.relatedTarget;
      self.$el.find('.order-details').html($(button).data('details'));
    });
  }

  show() {
    this.$el.modal();
  }
}

window.OrderDetailsModal = OrderDetailsModal;
