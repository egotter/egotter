function attach_event_handler(name, url) {
  var selector = 'input[name=' + name + ']';

  $(selector + ':checkbox').on('change', function () {
    var val = $(selector + ':checked').val() ? true : false;
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