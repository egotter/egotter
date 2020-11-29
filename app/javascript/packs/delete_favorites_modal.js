class DeleteFavoritesModal {
  constructor(id, url, i18n) {
    var $modal = $('#' + id);
    var caller = null;

    $modal.on('show.bs.modal', function (e) {
      caller = e.relatedTarget;
    });

    $modal.find('.positive').on('click', function () {
      var input = $modal.find('.confirm-input');
      if (!input.val() || input.val() !== i18n['confirmationText']) {
        ToastMessage.warn(i18n['pleaseEnterConfirmationText']);
        return;
      }

      $modal.modal('hide');

      if (caller) {
        $(caller).addClass('disabled').attr('disabled', 'disabled').prop("disabled", true);
      }

      var tweet = $modal.find('#tweet-after-finishing').prop('checked');

      $.post(url, {tweet: tweet}).done(function (res) {
        logger.log(res);

        setTimeout(function () {
          window.location.reload();
        }, 3000);
      }).fail(showErrorMessage);
    });
  }
}

window.DeleteFavoritesModal = DeleteFavoritesModal;
