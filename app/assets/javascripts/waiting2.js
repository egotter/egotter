'use strict';

function waiting2(twitterUser, action, scope) {
  var Interval = function () {
    this.value = 2000;
    this.max = 5000;
  };

  Interval.prototype.current = function () {
    return this.value;
  };

  Interval.prototype.next = function () {
    this.value += 2000;
    if (this.value > this.max) this.value = this.max;
    return this.value;
  };

  var Retry = function () {
    this.count = 0;
    this.max = 10;
  };

  Retry.prototype.current = function () {
    return this.count;
  };

  Retry.prototype.next = function () {
    this.count += 1;
    return this.count < this.max;
  };

  var refreshBox = $('.refresh-box');
  var latestBox = $('.latest-box');

  refreshBox.find('a').on('click', function (e) {
    e.preventDefault();
    e.stopPropagation();

    cache.delete(twitterUser.uid)
      .then(cache.create(twitterUser.uid))
      .then(function () {
        console.log(new Date() + ': reload started');
        window.location.reload();
      })
      .fail(failed);

    return false;
  });

  var interval = new Interval();
  var retry = new Retry();
  var cache = new egotter.PageCache();
  var pollingStart = performance.now();

  function createPollingLog(status) {
    var elapsedTime = performance.now() - pollingStart;
    if (elapsedTime < 120) {
      var url = egotter.pollingLogsPath.replace(/UID/, twitterUser.uid).replace(/SCREEN_NAME/, twitterUser.screenName);
      $.post(url, {_action: action, status: status, time: elapsedTime, retry_count: retry.current()});
    }
  }

  function failed(xhr) {
    console.log('Server failed.');
    createPollingLog(false);
    console.log(xhr.responseText);
  }

  function done(res, text_status, xhr) {
    console.log(res, text_status, xhr.status, interval.current(), retry.current());

    if (xhr.status === 200) {
      console.log(new Date(twitterUser.createdAt * 1000), new Date(res.created_at * 1000));
      createPollingLog(true);

      if (twitterUser.createdAt < res.created_at) {
        cache.setHash(res.hash);
        refreshBox.show();
        refreshBox.sticky({topSpacing: 0});
      } else {
        latestBox.show();
      }

      return;
    }

    if (!retry.next()) {
      console.log('Stop waiting.');
      createPollingLog(false);
      // Rollbar.scope(scope).warning("Retries exhausted while attempting fetching.");
    } else {
      setTimeout(tic, interval.next());
    }
  }

  function tic() {
    var url = egotter.backgroundSearchLogPath.replace(/UID/, twitterUser.uid);
    $.get(url).done(done).fail(failed);
  }

  tic();
}

function searchResultsWaiting(twitterUser, scope) {
  waiting2(twitterUser, 'search_results/show', scope)
}

