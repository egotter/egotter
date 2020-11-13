class EndTrialModal {
  constructor(id) {
    this.$el = $('#' + id);
    this.init();
  }

  init() {
    var url = '/api/v1/orders/end_trial'; // api_v1_orders_end_trial_path

    this.$el.find('.positive').on('click', function () {
      $.post(url).done(function (res) {
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
    });
  }

  show() {
    this.$el.modal();
  }
}

window.EndTrialModal = EndTrialModal;
