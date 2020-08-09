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
