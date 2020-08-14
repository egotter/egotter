class SecretModeDetector {
  constructor(options) {
    Object.assign(this, options);
  }

  detect() {
    var self = this;
    if ('storage' in navigator && 'estimate' in navigator.storage) {
      navigator.storage.estimate().then(function (estimate) {
        // var usage = estimate.usage;
        var quota = estimate.quota;

        if (quota < 120000000) {
          console.log('Incognito');
          self.detected(quota);
        } else {
          console.log('Not Incognito');
        }
      });
    } else {
      // This feature is available only in secure contexts (HTTPS)
      console.log('Can not detect');
    }
  }

  detected() {
    if (this.allowCognite || this.signedIn) {
      return;
    }
    if (this.os === 'Android' && this.osVersion.match(/^(6|5|4)/)) {
      return;
    }

    ToastMessage.warn(this.message);

    if (this.force) {
      var redirectPath = this.redirectPath;
      setTimeout(function () {
        window.location.href = redirectPath;
      }, 2000);
    }

    ga('send', {
      hitType: 'event',
      eventCategory: this.eventCategory,
      eventAction: 'SecretMode detected',
      eventLabel: this.eventLabel
    });
  }
}

window.SecretModeDetector = SecretModeDetector;

// class SecretModeDetector_old {
//   constructor() {
//     var fs = window.RequestFileSystem || window.webkitRequestFileSystem;
//     if (fs) {
//       fs(window.TEMPORARY,
//           100,
//           function () {
//             console.log('Not Incognito');
//           },
//           function () {
//             console.log('Incognito');
//           });
//     } else {
//       console.log('Can not detect');
//     }
//   }
// }

class AdBlockDetector {
  constructor(options) {
    Object.assign(this, options);
  }

  detect() {
    if (document.getElementById('poinpgwawoiwoignsdoa')) {
      console.log('Blocking Ads: No');
    } else {
      console.log('Blocking Ads: Yes');
      this.detected();
    }
  }

  detected() {
    ToastMessage.warn(this.message);

    if (this.force) {
      var redirectPath = this.redirectPath;
      setTimeout(function () {
        window.location.href = redirectPath;
      }, 2000);
    }

    ga('send', {
      hitType: 'event',
      eventCategory: this.eventCategory,
      eventAction: 'AdBlocker detected',
      eventLabel: this.eventLabel
    });
  }
}

window.AdBlockDetector = AdBlockDetector;

class Polling {
  constructor(options) {
    Object.assign(this, options);
  }

  start(doneCallback, failCallback) {
    var self = this;

    var done = function (res) {
      console.log(self.constructor.name, 'done', res);
      doneCallback();
    };

    var stopped = function (res, reason) {
      console.warn(self.constructor.name, 'stopped', reason, res);
      failCallback('stopped');
    };

    var failed = function (xhr) {
      console.log(self.constructor.name, 'failed', xhr.responseText);
      failCallback('failed');
    };

    this.poll(this.url, {retry_count: 0}, done, stopped, failed);
  }

  poll(path, options, done, stopped, failed) {
    var maxRetryCount = 5;
    var interval = 3000;
    console.log(this.constructor.name, 'poll', options);

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
      console.warn(self.constructor.name, 'failed', xhr.responseText);
      callback();
    });
  }
}

window.FetchChangesText = FetchChangesText;
