class Order {
  constructor(id, i18n) {
    this.id = id;
    this.i18n = i18n;
  }

  cancel() {
    var url = '/api/v1/orders/cancel'; // api_v1_orders_cancel_path
    var id = this.id;
    var i18n = this.i18n;

    ToastMessage.info(i18n['processing']);

    $.post(url, {id: id}).done(function (res) {
      ToastMessage.info(res.message);
      setTimeout(function () {
        window.location.reload();
      }, 5000);
    }).fail(showErrorMessage);
  }
}

window.Order = Order;
