function attach_event_handler(name, url) {
  var selector = 'input[name=' + name + ']';

  $(selector + ':checkbox').on('change', function () {
    var val = !!$(selector + ':checked').val();
    var params = {};
    params[name] = val;
    $.ajax({url: url, method: 'PATCH', data: params})
      .done(function (res) {
        console.log(res);
        $('.blink.' + name).fadeIn(2000).fadeOut(2000);
      })
      .fail(function (xhr) {
        console.log(xhr.responseText);
      });
  });
}

var Settings = {};

Settings.enableDeleteTweetsButton = function () {
  $('.trial-delete-submit-btn').on('click', function (e) {
    $('#trial-delete-modal').modal('hide');
    $('.trial-delete-btn').attr('disabled', 'disabled')
        .prop("disabled", true);
    $.post($(this).data('url'), function (res) {
      console.log(res);
    });
  });
};
