'use strict';

class PeriodicReportSetting {
  constructor(url, confirmMessage) {
    this.url = url;
    this.confirmMessage = confirmMessage;
    var self = this;

    ['morning', 'afternoon', 'evening', 'send_only_if_changed'].forEach(function (name) {
      $('#' + name).on('change', function () {
        var $checkbox = $(this);

        var val = $checkbox.prop('checked');
        console.log('changed', name, val);

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
      console.log('res', res);
    }).fail(function (xhr) {
      console.warn(xhr.responseText);
    });
  }
}

window.PeriodicReportSetting = PeriodicReportSetting;
