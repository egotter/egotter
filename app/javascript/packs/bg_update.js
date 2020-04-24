'use strict';

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

class UnauthorizedDetector {
  constructor(options) {
    Object.assign(this, options);
  }

  detect() {
    var self = this;
    $.get(this.url).done(function (res) {
      console.log('accountStatus', res);

      if (!res.authorized) {
        self.unauthorized();
      } else if (res.egotter_blocked) {
        self.blocked();
      }
    }).fail(function (xhr) {
      console.log('failed', self.url, xhr.responseText);
    });
  }

  unauthorized() {
    ToastMessage.warn(this.unauthorizedMessage);

    if (this.force) {
      var redirectPath = this.unauthorizedRedirectPath;
      setTimeout(function () {
        window.location.href = redirectPath;
      }, 2000);
    }

    ga('send', {
      hitType: 'event',
      eventCategory: this.eventCategory,
      eventAction: 'Unauthorized detected',
      eventLabel: this.eventLabel
    });
  }

  blocked() {
    ToastMessage.warn(this.blockedMessage);

    var redirectPath = this.blockedRedirectPath;
    setTimeout(function () {
      window.location.href = redirectPath;
    }, 2000);

    ga('send', {
      hitType: 'event',
      eventCategory: this.eventCategory,
      eventAction: 'egotterBlocked detected',
      eventLabel: this.eventLabel
    });
  }
}

window.UnauthorizedDetector = UnauthorizedDetector;

class EgotterFollowerDetector {
  constructor(options) {
    Object.assign(this, options);
  }

  detect(callback) {
    var self = this;
    $.getJSON(this.url).done(function (res) {
      console.log(self.constructor.name, 'done', res);
      if (res.follow) {
        callback();
      } else {
        self.notFollowing();
      }
    }).fail(function (xhr) {
      console.log(self.constructor.name, 'failed', xhr.responseText);
    });
  }

  notFollowing() {
    var message = $('#follow-box .inner').html();
    ToastMessage.warn(message);
  }
}

window.EgotterFollowerDetector = EgotterFollowerDetector;

class CreateTwitterUserRequest {
  constructor(options) {
    Object.assign(this, options);
  }

  perform(callback) {
    var self = this;

    var done = function (res) {
      console.log(self.constructor.name, 'done', res);

      if (res.jid) {
        callback();
      } else {
        console.warn(self.constructor.name, "Job is not started.");
      }
    };

    var failed = function (xhr) {
      console.warn(self.constructor.name, 'failed', xhr.responseText);

      var error = self.parseError(xhr);

      if (error === 'too_many_searches') {
        ToastMessage.info($('#too-many-searches-box .inner').html());
      } else {
        ToastMessage.info($('#retry-later-box .inner').html());
      }
    };

    var params = {uid: this.twitterUser.uid};
    $.post(this.url, params).done(done).fail(failed);
  }

  parseError(xhr) {
    var err = 'Something';
    try {
      err = JSON.parse(xhr.responseText)['error'];
    } catch (e) {
      console.error(e);
    }
    return err;
  }
}

window.CreateTwitterUserRequest = CreateTwitterUserRequest;

class Polling {
  constructor(options) {
    Object.assign(this, options);
  }

  start() {
    var self = this;

    var done = function (res) {
      console.log(self.constructor.name, 'done', res);
      self.fetchChangesText(self.changesPath, function (message) {
        ToastMessage.info(message);
      });
    };

    var stopped = function (res, reason) {
      console.warn(self.constructor.name, 'stopped', reason, res);
      ToastMessage.info($('#request-to-update-box .inner').html());
    };

    var failed = function (xhr) {
      console.log(self.constructor.name, 'failed', xhr.responseText);
      ToastMessage.warn($('#retry-later-box .inner').html());
    };

    var options = {retry_count: 0};
    this.poll(this.url, options, done, stopped, failed);
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


  fetchChangesText(url, callback) {
    var self = this;
    $.get(url).done(function (res) {
      var message = $('#refresh-box .inner');
      if (res.text) {
        message.find('.message').text(res.text);
      }
      callback(message.html());
    }).fail(function (xhr) {
      console.warn(self.constructor.name, 'failed', url, xhr.responseText);
      callback($('#refresh-box .inner').html());
    });
  }
}

window.Polling = Polling;
