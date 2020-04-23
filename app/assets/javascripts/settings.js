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

var Settings = {};

Settings.enableUpdateReportIntervalButton = function (url, beforeChange) {
  var previous;

  $('.settings #report_interval').on('focus', function () {
    previous = this.value;
  }).on('change', function () {
    var $selected = $(this);
    var value = $selected.val();
    var label = $selected.find('option:selected').text();
    $selected.blur();

    console.log('report_interval', previous, value, label);

    if (beforeChange(value, label)) {
      $.post(url, {report_interval: value}).done(function (res) {
        console.log(res);
      }).fail(function (xhr) {
        console.log(xhr.responseText);
      });
    } else {
      $selected.val(previous);
    }
  });
};

Settings.enableDeleteTweetsButton = function (id, url) {
  var $modal = $('#' + id);
  $modal.find('.positive').on('click', function (e) {
    $modal.modal('hide');
    $('.delete-tweets-btn').attr('disabled', 'disabled')
        .prop("disabled", true);

    var tweet = $modal.find('#tweet-after-finishing').prop('checked');

    $.post(url, {tweet: tweet}).done(function (res) {
      console.log(res);

      setTimeout(function () {
        window.location.reload();
      }, 3000);
    }).fail(function (xhr) {
      SnackMessage.alert(JSON.parse(xhr.responseText)['message']);
    });
  });
};

Settings.activateResetEgotterButton = function (id, url) {
  var $modal = $('#' + id);
  $modal.find('.positive').on('click', function (e) {
    $modal.modal('hide');
    $('.reset-egotter-btn').attr('disabled', 'disabled')
        .prop("disabled", true);

    $.ajax({url: $(this).data('url'), type: 'DELETE'})
        .done(function (res) {
          console.log(res);
        });
  });
};

Settings.activateResetCacheButton = function (id, url) {
  var $modal = $('#' + id);
  $modal.find('.positive').on('click', function (e) {
    $modal.modal('hide');
    $('.reset-cache-btn').attr('disabled', 'disabled')
        .prop("disabled", true);
    $.post($(this).data('url'), function (res) {
      console.log(res);
    });
  });
};
