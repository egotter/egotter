class SecretModeDetector {
  detect(callback) {
    this.detectByStorageQuota(callback);
    this.detectByFileSystem(callback);
  }

  detectByStorageQuota(callback) {
    if ('storage' in navigator && 'estimate' in navigator.storage) {
      navigator.storage.estimate().then(function (estimate) {
        // var usage = estimate.usage;
        var quota = estimate.quota;

        if (quota < 120000000) {
          logger.log('Incognito');
          callback(quota);
        } else {
          logger.log('Not Incognito', quota);
        }
      });
    } else {
      // This feature is available only in secure contexts (HTTPS)
      logger.log('Can not detect');
    }
  }

  detectByFileSystem(callback) {
    var fs = window.RequestFileSystem || window.webkitRequestFileSystem;
    if (fs) {
      fs(window.TEMPORARY,
          100,
          function () {
            logger.log('Not Incognito');
          },
          function () {
            logger.log('Incognito');
            callback();
          });
    } else {
      logger.log('Can not detect');
    }
  }
}

window.SecretModeDetector = SecretModeDetector;

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
