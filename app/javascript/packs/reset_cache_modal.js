class ResetCacheModal {
  constructor(id) {
    this.$el = $('#' + id);
    this.init();
  }

  init() {
    var url = '/api/v1/user_caches'; // api_v1_user_caches_path
    var self = this;

    this.$el.on('show.bs.modal', function (e) {
      if (e.relatedTarget) {
        self.button = e.relatedTarget;
      }

      var page = window.location.href;
      var text = $(self.button).text().trim();
      ahoy.track('Modal', {name: 'reset_cache', page: page, text: text});
    });

    this.$el.find('.positive').on('click', function () {
      if (self.button) {
        $(self.button).addClass('disabled').attr('disabled', 'disabled').prop("disabled", true);
      }

      $.ajax({url: url, type: 'DELETE'}).done(function (res) {
        ToastMessage.info(res.message);
      }).fail(showErrorMessage);
    });
  }
}

window.ResetCacheModal = ResetCacheModal;
