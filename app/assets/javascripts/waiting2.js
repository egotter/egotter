'use strict';

function waiting2(twitterUser, callback) {
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

  var interval = new Interval();
  var retry = new Retry();
  var pollingStart = Date.now();

  function createPollingLog(uid, screenName, status, startTime, retryCount) {
    var elapsedTime = (Date.now() - startTime) / 1000.0;
    if (elapsedTime < 120.0) {
      var url = egotter.pollingLogsPath.replace(/UID/, uid).replace(/SCREEN_NAME/, screenName);
      $.post(url, {_action: 'search_results/show', status: status, time: elapsedTime, retry_count: retryCount});
    }
  }

  function done(res, textStatus, xhr) {
    console.log(res, textStatus, xhr.status, interval.current(), retry.current());

    if (xhr.status === 200) {
      createPollingLog(twitterUser.uid, twitterUser.screenName, true, pollingStart, retry.current());
      callback(res, textStatus, xhr);
      return;
    }

    if (!retry.next()) {
      console.log('stop waiting');
      createPollingLog(twitterUser.uid, twitterUser.screenName, false, pollingStart, retry.current());
      console.log(xhr.responseText);
      return;
    }

    setTimeout(tic, interval.next());
  }

  function tic() {
    var url = egotter.backgroundSearchLogPath.replace(/UID/, twitterUser.uid);
    $.get(url).done(done).fail(function (xhr) {
      console.log('tic failed');
      createPollingLog(twitterUser.uid, twitterUser.screenName, false, pollingStart, retry.current());
      console.log(xhr.responseText);
    });
  }

  tic();
}
