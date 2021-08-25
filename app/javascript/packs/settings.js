class PeriodicReportSetting {
  constructor(url) {
    this.url = url;
    var self = this;

    ['morning', 'afternoon', 'evening'].forEach(function (name) {
      $('#' + name).on('change', function () {
        var $checkbox = $(this);

        var val = $checkbox.prop('checked');
        logger.log('changed', name, val);
        self.update(name, val);
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
