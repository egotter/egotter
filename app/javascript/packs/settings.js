class ResetEgotterButton {
  constructor(id, url) {
    var $modal = $('#' + id);

    $modal.find('.positive').on('click', function () {
      $modal.modal('hide');
      $('.reset-egotter-btn').addClass('disabled').attr('disabled', 'disabled').prop("disabled", true);

      $.ajax({url: url, type: 'DELETE'}).done(function (res) {
        console.log(res);
      }).fail(function (xhr) {
        console.warn(xhr.responseText);
      });
    });
  }
}

window.ResetEgotterButton = ResetEgotterButton;

class ResetCacheButton {
  constructor(id, url) {
    var $modal = $('#' + id);

    $modal.find('.positive').on('click', function () {
      $modal.modal('hide');
      $('.reset-cache-btn').addClass('disabled').attr('disabled', 'disabled').prop("disabled", true);

      $.post(url).done(function (res) {
        console.log(res);
      }).fail(function (xhr) {
        console.warn(xhr.responseText);
      });
    });
  }
}

window.ResetCacheButton = ResetCacheButton;

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
