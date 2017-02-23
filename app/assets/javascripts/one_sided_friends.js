function fetchFirstUsers(url, $tab, callback) {
  var selector = $tab.attr('href');

  $.get(url.replace('TYPE', selector.replace('#', '').replace(/-/g, '_')))
    .done(function (res) {
      if (res.empty) {
        $tab.data('present', false);
        $(selector).empty().append(egotter.messages.empty());
      } else {
        $tab.data('present', true);
        $(selector).empty().append(res.html);
        callback();
      }
    })
    .fail(function (xhr) {
      if (xhr.status === 502) {
        var message = egotter.messages.retryTimeout(egotter.controller_name + '/' + egotter.action_name + '/client/retry_timeout');
        $(selector).empty().append(message);
      } else {
        var message = egotter.messages.somethingWrong(egotter.controller_name + '/' + egotter.action_name + '/client/something_wrong');
        $(selector).empty().append(message);
      }
      console.log(xhr.responseText);
    });
}

function tabClicked (e) {
  e.preventDefault();
  var $tab = $(this);
  var $box = $('.shown-later');
  if($tab.data('loaded')){
    if($tab.data('present')){
      $box.show();
    } else {
      $box.hide();
    }
  } else {
    $tab.data('loaded', true);
    $box.hide();
    fetchFirstUsers(e.data.url, $tab, function () {
      $box.show();
      var path = window.location.pathname + window.location.search + '#loaded';
      window.history.replaceState(null, null, path)
    });
  }
}