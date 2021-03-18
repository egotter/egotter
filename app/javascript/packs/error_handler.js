class ErrorHandler {
  constructor(attrs) {
    this.userId = attrs['userId'];
    this.visitId = attrs['visitId'];
    this.controllerAction = attrs['controllerAction'];
    this.deviceType = attrs['deviceType'];
    this.os = attrs['os'];
    this.browser = attrs['browser'];
  }

  handle(kind, message) {
    this.sendGoogleAnalytics(kind, message);
    this.sendAhoy(kind, message);
  }

  sendGoogleAnalytics(kind, message) {
    var eventParams = {
      hitType: 'event',
      eventCategory: 'JS Exception',
      eventAction: kind + ' / ' + this.controllerAction,
      eventLabel: JSON.stringify({
        userId: this.userId,
        visitId: this.visitId,
        deviceType: this.deviceType,
        os: this.os,
        browser: this.browser,
        cookie: navigator.cookieEnabled,
        message: message,
        path: window.location.href,
        referer: document.referrer
      })
    };

    try {
      if (ga) {
        ga('send', eventParams);
        console.warn('Sent JS Exception to GA', kind, eventParams);
      } else {
        console.warn('ga() is not defined', kind, eventParams);
      }
    } catch (e) {
      console.error('Sending JS Exception to GA is failed', e);
    }
  }

  sendAhoy(kind, message) {
    if (this.controllerAction === 'home#new') {
      var eventParams = {
        os: this.os,
        browser: this.browser,
        cookie: navigator.cookieEnabled,
        message: message,
        path: window.location.href,
        referer: document.referrer
      };

      ahoy.track('JS Exception (' + kind + ')', eventParams);
    }
  }
}

window.ErrorHandler = ErrorHandler;
