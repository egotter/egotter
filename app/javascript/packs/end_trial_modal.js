class EndTrialModal {
  constructor(id, i18n) {
    this.$el = $('#' + id);
    this.i18n = i18n;
    this.init();
  }

  init() {
    var url = '/api/v1/orders/end_trial'; // api_v1_orders_end_trial_path
    var i18n = this.i18n;
    var self = this;

    this.$el.on('show.bs.modal', function (e) {
      if (e.relatedTarget) {
        self.button = e.relatedTarget;
      }

      var page = window.location.href;
      var text = $(self.button).text().trim();
      ahoy.track('Modal', {name: 'end_trial', page: page, text: text});
    });

    this.$el.find('.positive').on('click', function () {
      if (self.button) {
        $(self.button).addClass('disabled').attr('disabled', 'disabled').prop("disabled", true);
      }

      ToastMessage.info(i18n['processing']);

      $.post(url).done(function (res) {
        ToastMessage.info(res.message);
        var interval = (res.interval || 10) * 1000;

        setTimeout(function () {
          window.location.reload();
        }, interval);
      }).fail(showErrorMessage);
    });
  }

  show(button) {
    this.button = button;
    this.$el.modal();
  }
}

window.EndTrialModal = EndTrialModal;
