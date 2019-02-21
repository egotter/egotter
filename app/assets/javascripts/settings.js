function attach_event_handler(name, url) {
  var selector = 'input[name=' + name + ']';

  var $checkbox = $('.settings #' + name + '-input');
  if (!$checkbox.data('checked')) {
    $checkbox.removeAttr('checked');
  }

  $(selector + ':checkbox').on('change', function () {
    var val = !!$(selector + ':checked').val();
    var params = {};
    params[name] = val;
    $.ajax({url: url, method: 'PATCH', data: params})
      .done(function (res) {
        console.log(res);
      })
      .fail(function (xhr) {
        console.log(xhr.responseText);
      });
  });
}

var Settings = {};

Settings.enableDeleteTweetsButton = function () {
  var $modal = $('#delete-tweets-modal');
  $modal.find('.ok').on('click', function (e) {
    $modal.modal('hide');
    $('.delete-tweets-btn').attr('disabled', 'disabled')
        .prop("disabled", true);
    $.post($(this).data('url'), function (res) {
      console.log(res);
    });
  });
};

Settings.enableResetEgotterButton = function () {
  var $modal = $('#reset-egotter-modal');
  $modal.find('.ok').on('click', function (e) {
    $modal.modal('hide');
    $('.reset-egotter-btn').attr('disabled', 'disabled')
        .prop("disabled", true);
    $.post($(this).data('url'), function (res) {
      console.log(res);
    });
  });
};

Settings.enableUpdateProfileButton = function (callback) {
  $('.update-profile').on('click', function (e) {
    e.preventDefault();
    var $clicked = $(this);
    $.post($clicked.data('url'), function (res) {
      console.log(res);
      if (callback) {
        callback(res);
      }
    });
    return false;
  });
};
