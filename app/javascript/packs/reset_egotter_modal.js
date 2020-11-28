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
      }).fail(showErrorMessage);
    });
  }

  show() {
    this.$el.modal();
  }
}

window.ResetEgotterModal = ResetEgotterModal;
