class Checkout {
  constructor(key, url, i18n) {
    this.key = key;
    this.url = url;
    this.i18n = i18n;
  }

  enableCheckoutButtons() {
    var self = this;

    $(document).on('click', '.btn-checkout', function () {
      self.createCheckoutSession('subscription', function (session_id) {
        self.redirectToCheckout(session_id);
      });
      return false;
    });

    $(document).on('click', '.btn-one-time-checkout', function () {
      self.createCheckoutSession($(this).data('item-id'), function (session_id) {
        self.redirectToCheckout(session_id);
      });
      return false;
    });
  }

  redirectToCheckout(session_id) {
    var stripe = Stripe(this.key);
    stripe.redirectToCheckout({sessionId: session_id}).then(function (result) {
      logger.log(result.error.message);
    });
  }

  createCheckoutSession(item_id, callback) {
    var url = this.url + '&item_id=' + item_id;
    $.post(url).done(function (res) {
      callback(res.session_id);
    }).fail(showErrorMessage);
  }

  disableCheckoutButton($btn) {
    var i18n = this.i18n;
    if (!$btn.data('btn-disabled')) {
      $btn.data('btn-disabled', true)
          .attr('disabled', 'disabled')
          .addClass('disabled')
          .text(i18n.alreadyPurchased);
    }
    return false;
  }

  disableCheckoutButtons() {
    var self = this;
    $('.btn-checkout, .btn-one-time-checkout').each(function () {
      self.disableCheckoutButton($(this));
    });

    $(document).on('click', '.btn-checkout, .btn-one-time-checkout', function () {
      return self.disableCheckoutButton($(this));
    });
  }

  enableEndTrialButton() {
    $(document).on('click', '.btn-end-trial', function () {
      if (window.endTrialModal) {
        window.endTrialModal.show(this);
        return false;
      }
    });
  }

  enableRedirectingToLogin() {
    $(document).on('click', '.btn-checkout, .btn-one-time-checkout', function () {
      var url = '/login?via=btn_checkout'; // login_path
      window.location.href = url;
      return false;
    });
  }

}

window.Checkout = Checkout;
