'use strict';

function waiting2(checkLogPath, pageCachePath, pageCachesPath, pollingLogsPath, action, createdAt, scope) {
  var Cache = function () {
    this.hash = 'xxx';
  };

  Cache.prototype.setHash = function (hash) {
    this.hash = hash;
  };

  Cache.prototype.delete = function () {
    console.log(new Date() + ': delete started');
    return $.ajax({url: pageCachePath.replace(/HASH/, this.hash), type: 'DELETE'});
  };

  Cache.prototype.create = function create() {
    console.log(new Date() + ': create started');
    return $.post(pageCachesPath);
  };

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

  var refreshBox = $('.alert.alert-info');
  refreshBox.find('a').on('click', function (e) {
    e.preventDefault();
    e.stopPropagation();

    cache.delete()
      .then(cache.create)
      .then(function () {
        console.log(new Date() + ': reload started');
        window.location.reload();
      })
      .fail(failed);

    return false;
  });

  var interval = new Interval();
  var retry = new Retry();
  var cache = new Cache();
  var pollingStart = performance.now();

  function failed(xhr) {
    console.log('Server failed.');
    $.post(pollingLogsPath, {_action: action, status: false, time: performance.now() - pollingStart, retry_count: retry.current()});
    console.log(xhr.responseText);
  }

  function done(res, text_status, xhr) {
    console.log(res, text_status, xhr.status, interval.current(), retry.current());

    if (xhr.status === 200) {
      console.log(new Date(createdAt * 1000), new Date(res.created_at * 1000));
      $.post(pollingLogsPath, {_action: action, status: true, time: performance.now() - pollingStart, retry_count: retry.current()});

      if (createdAt < res.created_at) {
        cache.setHash(res.hash);
        refreshBox.show();
        refreshBox.sticky({topSpacing: 0});
      } else {
        console.log('Do nothing.');
      }

      return;
    }

    if (!retry.next()) {
      console.log('Stop waiting.');
      $.post(pollingLogsPath, {_action: action, status: false, time: performance.now() - pollingStart, retry_count: retry.current()});
      Rollbar.scope(scope).warning("Retries exhausted while attempting fetching.");
    } else {
      setTimeout(tic, interval.next());
    }
  }

  function tic() {
    $.get(checkLogPath).done(done).fail(failed);
  }

  tic();
}

function searchResultsWaiting(checkLogPath, pageCachePath, pageCachesPath, pollingLogsPath, createdAt, scope) {
  waiting2(checkLogPath, pageCachePath, pageCachesPath, pollingLogsPath, 'search_results/show', createdAt, scope)
}

