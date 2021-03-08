class Polling {
  constructor(options) {
    Object.assign(this, options);
  }

  start(doneCallback, failCallback) {
    var self = this;

    var done = function (res) {
      logger.log(self.constructor.name, 'done', res);
      doneCallback();
    };

    var stopped = function (res, reason) {
      logger.warn(self.constructor.name, 'stopped', reason, res);
      failCallback('stopped');
    };

    var failed = function (xhr) {
      logger.log(self.constructor.name, 'failed', xhr.responseText);
      failCallback('failed');
    };

    this.poll(this.url, {retry_count: 0}, done, stopped, failed);
  }

  poll(path, options, done, stopped, failed) {
    var maxRetryCount = 5;
    var interval = 3000;
    logger.log(this.constructor.name, 'poll', options);

    var self = this;

    $.get(path, options)
        .done(function (res) {
          if (res.created_at > self.twitterUser.createdAt) {
            // New record found
            done(res);
            return;
          }

          if (options['retry_count'] < maxRetryCount - 1) {
            setTimeout(function () {
              options['retry_count']++;
              self.poll(path, options, done, stopped, failed);
            }, interval);
          } else {
            stopped(res, 'Retry exhausted');
          }
        })
        .fail(failed);
  }
}

window.Polling = Polling;

class FetchChangesText {
  constructor(url) {
    this.url = url;
  }

  fetch(callback) {
    $.get(this.url).done(function (res) {
      callback(res.text);
    }).fail(function (xhr) {
      logger.warn(self.constructor.name, 'failed', xhr.responseText);
      callback();
    });
  }
}

window.FetchChangesText = FetchChangesText;
