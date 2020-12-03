class ResetCacheModal {
  constructor(id) {
    this.$el = $('#' + id);
    this.init();
  }

  init() {
    var url = '/api/v1/user_caches'; // api_v1_user_caches_path

    this.$el.find('.positive').on('click', function () {
      $.ajax({url: url, type: 'DELETE'}).done(function (res) {
        ToastMessage.info(res.message);
      }).fail(showErrorMessage);
    });
  }

  show() {
    this.$el.modal();
  }
}

window.ResetCacheModal = ResetCacheModal;
