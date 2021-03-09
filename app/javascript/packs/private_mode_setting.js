class PrivateModeSetting {
  constructor(selector) {
    var self = this;

    $('#' + selector).on('change', function () {
      var $checkbox = $(this);

      var val = $checkbox.prop('checked');
      logger.log('changed', selector, val);

      if (val) {
        self.create();
      } else {
        self.destroy();
      }
    });
  }

  create() {
    var url = '/api/v1/private_mode_settings'; // api_v1_private_mode_settings_path
    $.post(url).done(function (res) {
      ToastMessage.info(res.message);
    }).fail(showErrorMessage);
  }

  destroy() {
    var url = '/api/v1/private_mode_settings'; // api_v1_private_mode_settings_path
    $.ajax({url: url, type: 'DELETE'}).done(function (res) {
      ToastMessage.info(res.message);
    }).fail(showErrorMessage);
  }
}

window.PrivateModeSetting = PrivateModeSetting;
