class DeleteTweetsModal {
  constructor(id, url, i18n) {
    var $modal = $('#' + id);
    var caller = null;

    $modal.on('shown.bs.modal', function (e) {
      caller = e.relatedTarget;

      $modal.find('#since-date-confirmation').text($modal.data('since') || i18n['notSpecified']);
      $modal.find('#until-date-confirmation').text($modal.data('until') || i18n['notSpecified']);

      $modal.find('#send-dm-confirmation').text($modal.data('dm') ? i18n['send'] : i18n['notSent']);
      $modal.find('#post-tweet-confirmation').text($modal.data('tweet') ? i18n['post'] : i18n['notPosted']);
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

      var options = {
        since: $modal.data('since'),
        until: $modal.data('until'),
        dm: $modal.data('dm'),
        tweet: $modal.data('tweet')
      };

      $.post(url, options).done(function (res) {
        ToastMessage.info(res.message);

        setTimeout(function () {
          window.open(res.url, '_blank');
        }, 3000);
      }).fail(showErrorMessage);
    });
  }
}

window.DeleteTweetsModal = DeleteTweetsModal;
