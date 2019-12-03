function attach_event_handler(name, url) {
  var $checkbox = $('.settings #' + name + '-input');

  $checkbox.on('change', function () {
    var val = $checkbox.prop('checked');
    console.log(name, val);

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

function attach_report_interval_handler(url) {
  var $selectbox = $('.settings #report_interval');

  $selectbox.on('change', function () {
    var name = 'report_interval';
    var val = $(this).val();
    console.log(name, val);

    var params = {};
    params[name] = val;
    $.ajax({url: url, method: 'POST', data: params})
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

    var tweet = $modal.find('#tweet-after-finishing').prop('checked');

    $.post($(this).data('url'), {tweet: tweet}, function (res) {
      console.log(res);

      setTimeout(function () {
        window.location.reload();
      }, 3000);
    });
  });
};

Settings.enableResetEgotterButton = function () {
  var $modal = $('#reset-egotter-modal');
  $modal.find('.ok').on('click', function (e) {
    $modal.modal('hide');
    $('.reset-egotter-btn').attr('disabled', 'disabled')
        .prop("disabled", true);

    $.ajax({url: $(this).data('url'), type: 'DELETE'})
        .done(function (res) {
          console.log(res);
        });
  });
};

Settings.enableResetCacheButton = function () {
  var $modal = $('#reset-cache-modal');
  $modal.find('.ok').on('click', function (e) {
    $modal.modal('hide');
    $('.reset-cache-btn').attr('disabled', 'disabled')
        .prop("disabled", true);
    $.post($(this).data('url'), function (res) {
      console.log(res);
    });
  });
};
