function loadSummary (apiEndpoint, uid, menuName, progressMessages) {
  var $summaryBox = $('.menu-items.' + menuName);
  var $progressMsgBox = $summaryBox.find('.progress-msg');

  var $resultLinkButtons = {
    reload: $summaryBox.find('.reload-btn'),
    more: $summaryBox.find('.btn-view-more')
  };

  $.getJSON(apiEndpoint, {uid: uid}, function(data) {
    console.log(data);

    if (!data || !data.users || data.users.length <= 0) {
      $summaryBox.find('.result-link').attr('href', '#').attr('onclick', 'return false;');
      $progressMsgBox.html(progressMessages.empty).show();
      $resultLinkButtons.reload.show();
      $("div[data-replaced-by='" + menuName + "']").remove();
      $(".menu-items." + menuName).show();
      return;
    }

    var $userTemplate = $summaryBox.find('.user-template');
    $.each(data.users, function () {
      var user = this;
      var $cloned = $userTemplate.clone();
      $cloned
        .attr('href', $cloned.attr('href').replace('SCREEN_NAME', user.screen_name))
        .removeClass('user-template')
        .find('img')
        .attr({src: user.profile_image_url_https, alt: user.screen_name})
        .end()
        .css('display', 'inline-block')
        .insertBefore($userTemplate);
    });
    $resultLinkButtons.more.find('span').text(data.count).end().show();

    var graphOption = $.extend(true, {}, window.common_pie_chart_options);
    graphOption.series[0].data = data.chart;

    $("div[data-replaced-by='" + menuName + "']").remove();
    $summaryBox.show();

    $summaryBox.find('.media-right').show().end().find('.common-chart').highcharts(graphOption);
  });
}

function checkForUpdates (path, interval, retryCount, foundCallback, stopCallback, failedCallback) {
  $.get(path)
    .done(function (res) {
      console.log('checkForUpdates', res);

      if (res.found) {
        foundCallback(res);
      } else {
        if (retryCount < 2) {
          function doRetry () {
            checkForUpdates(path, interval, ++retryCount, foundCallback, stopCallback, failedCallback);
          }
          setTimeout(doRetry, interval);
        } else {
          stopCallback(res);
        }
      }
    })
    .fail(function (xhr) {
      failedCallback(xhr);
    });
}