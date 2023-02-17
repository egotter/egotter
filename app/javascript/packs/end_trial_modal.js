class EndTrialModal {
  constructor(id, i18n) {
    this.$el = $('#' + id);
    this.i18n = i18n;
    this.init();
  }

  init() {
    var i18n = this.i18n;
    var self = this;

    this.$el.on('show.bs.modal', function (e) {
      if (e.relatedTarget) {
        self.button = e.relatedTarget;
      }

      window.trackModalEvent('EndTrialModal');
    });

    this.$el.find('.positive').on('click', function () {
      if (self.button) {
        $(self.button).addClass('disabled').attr('disabled', 'disabled').prop("disabled", true);
      }

      ToastMessage.info(i18n['processing']);

      self.postEndTrial(function (res) {
        setTimeout(function () {
          self.redirectOrReloadPage();
        }, (res.interval || 10) * 1000);
      });
    });
  }

  postEndTrial(callback) {
    var url = '/api/v1/orders/end_trial'; // api_v1_orders_end_trial_path
    if (this.button) {
      url += '?via=' + this.button.id;
    }

    $.post(url).done(function (res) {
      ToastMessage.info(res.message);
      callback(res);
    }).fail(showErrorMessage);
  }

  redirectOrReloadPage() {
    var url = '/api/v1/orders'; // api_v1_orders_path
    var failureUrl = '/orders/end_trial_failure'; // orders_end_trial_failure_path;
    if (this.button) {
      url += '?via=' + this.button.id;
      failureUrl += '?via=' + this.button.id;
    }

    $.get(url).done(function (res) {
      ToastMessage.info(res.message);
      setTimeout(function () {
        if (res.subscription) {
          window.location.reload();
        } else {
          window.location.href = failureUrl;
        }
      }, (res.interval || 10) * 1000);
    }).fail(showErrorMessage);
  }

  show(button) {
    this.button = button;
    this.$el.modal();
  }
}

window.EndTrialModal = EndTrialModal;
