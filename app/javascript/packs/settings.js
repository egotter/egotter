class PeriodicReportSetting {
  constructor(url, confirmMessage) {
    this.url = url;
    this.confirmMessage = confirmMessage;
    var self = this;

    ['morning', 'afternoon', 'evening', 'send_only_if_changed'].forEach(function (name) {
      $('#' + name).on('change', function () {
        var $checkbox = $(this);

        var val = $checkbox.prop('checked');
        logger.log('changed', name, val);

        if (name === 'send_only_if_changed' && !val) {
          if (confirm(self.confirmMessage)) {
            self.update(name, val);
          } else {
            $checkbox.prop('checked', true);
          }
        } else {
          self.update(name, val);
        }
      });
    });
  }

  update(name, val) {
    var params = {};
    params[name] = val;

    $.post(this.url, params).done(function (res) {
      logger.log('res', res);
    }).fail(showErrorMessage);
  }
}

window.PeriodicReportSetting = PeriodicReportSetting;

class PeriodicTweetSetting {
  constructor(selector, url) {
    this.url = url;
    var self = this;

    $(selector).on('change', function () {
      var $checkbox = $(this);

      var val = $checkbox.prop('checked');
      logger.log('changed', selector, val);
      self.update(val);
    });
  }

  update(val) {
    $.post(this.url, {value: val}).done(function (res) {
      ToastMessage.info(res.message);
    }).fail(showErrorMessage);
  }
}

window.PeriodicTweetSetting = PeriodicTweetSetting;
