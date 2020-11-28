class ResetEgotterModal {
  constructor(id) {
    this.$el = $('#' + id);
    this.init();
  }

  init() {
    var url = '/reset_egotter'; // reset_egotter_path

    this.$el.find('.positive').on('click', function () {
      $.ajax({url: url, type: 'DELETE'}).done(function (res) {
        ToastMessage.info(res.message);
      }).fail(function (xhr, textStatus, errorThrown) {
        var message = extractErrorMessage(xhr, textStatus, errorThrown);
        ToastMessage.warn(message);
      });
    });
  }

  show() {
    this.$el.modal();
  }
}

window.ResetEgotterModal = ResetEgotterModal;
