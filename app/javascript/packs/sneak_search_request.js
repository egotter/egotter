class SneakSearchRequest {
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
    var url = '/api/v1/sneak_search_requests'; // api_v1_sneak_search_requests_path
    $.post(url).done(function (res) {
      ToastMessage.info(res.message);
    }).fail(showErrorMessage);
  }

  destroy() {
    var url = '/api/v1/sneak_search_requests'; // api_v1_sneak_search_requests_path
    $.ajax({url: url, type: 'DELETE'}).done(function (res) {
      ToastMessage.info(res.message);
    }).fail(showErrorMessage);
  }
}

window.SneakSearchRequest = SneakSearchRequest;
