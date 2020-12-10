class SignInModal {
  constructor(id, url) {
    var $el = $('#' + id);

    $el.find('.btn.positive').on('click', function () {
      window.location.href = url;
    });

    $el.modal();
  }
}

window.SignInModal = SignInModal;
