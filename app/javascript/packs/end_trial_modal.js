class EndTrialModal {
  constructor(id, i18n) {
    this.$el = $('#' + id);
    this.i18n = i18n;
    this.init();
  }

  init() {
    var url = '/api/v1/orders/end_trial'; // api_v1_orders_end_trial_path
    var button = null;
    var i18n = this.i18n;

    this.$el.on('show.bs.modal', function (e) {
      button = e.relatedTarget;
    });

    this.$el.find('.positive').on('click', function () {
      if (button) {
        $(button).addClass('disabled').attr('disabled', 'disabled').prop("disabled", true);
      }

      ToastMessage.info(i18n['processing']);

      $.post(url).done(function (res) {
        ToastMessage.info(res.message);
        setTimeout(function () {
          window.location.reload();
        }, 5000);
      }).fail(showErrorMessage);
    });
  }

  show() {
    this.$el.modal();
  }
}

window.EndTrialModal = EndTrialModal;
