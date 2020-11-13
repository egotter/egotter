class Order {
  constructor(id) {
    this.id = id;
  }

  cancel() {
    var url = '/api/v1/orders/cancel'; // api_v1_orders_cancel_path
    var id = this.id;

    $.post(url, {id: id}).done(function (res) {
      ToastMessage.info(res.message);
    }).fail(function (xhr) {
      var message = 'error';
      try {
        message = JSON.parse(xhr.responseText)['message'];
      } catch (e) {
        logger.error(e);
      }
      ToastMessage.warn(message);
    });
  }
}

window.Order = Order;
