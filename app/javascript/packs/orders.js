class Order {
  constructor(id, i18n, via) {
    this.id = id;
    this.i18n = i18n;
    this.via = via;
  }

  cancel() {
    var url = '/api/v1/orders/cancel?via=' + this.via; // api_v1_orders_cancel_path
    var redirectUrl = '/orders/cancel?via=' + this.via; // orders_cancel_path
    var id = this.id;
    var i18n = this.i18n;
    var messageId = ToastMessage.info(i18n['processing']);

    $.post(url, {id: id}).done(function (res) {
      ToastMessage.info(res.message);

      setTimeout(function () {
        window.location = redirectUrl;
      }, (res.interval || 10) * 1000);
    }).fail(function (xhr, textStatus, errorThrown) {
      setTimeout(function () {
        ToastMessage.hide(messageId);
        showErrorMessage(xhr, textStatus, errorThrown);
      }, 500);
    });
  }
}

window.Order = Order;
