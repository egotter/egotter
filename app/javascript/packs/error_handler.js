class ErrorHandler {
  constructor(attrs) {
    this.userId = attrs['userId'];
    this.visitId = attrs['visitId'];
    this.method = attrs['method'];
    this.controllerAction = attrs['controllerAction'];
    this.deviceType = attrs['deviceType'];
    this.os = attrs['os'];
    this.browser = attrs['browser'];

    var self = this;

    window.onerror = function (message, filePath, rowNumber, columnNumber) {
      self.handle('onerror', 'message=' + message + '&filePath=' + filePath + '&rowNumber=' + rowNumber + '&columnNumber=' + columnNumber);
    };

    window.addEventListener('unhandledrejection', function (e) {
      self.handle('unhandledrejection', e.message);
    });
  }

  handle(kind, message) {
    this.sendGoogleAnalytics(kind, message);
    this.sendAhoy(kind, message);
  }

  sendGoogleAnalytics(kind, message) {
    var eventName = 'JS Exception';
    var eventParams = {
      hitType: 'event',
      eventCategory: eventName,
      eventAction: kind + ' / ' + this.controllerAction,
      eventLabel: JSON.stringify({
        userId: this.userId,
        visitId: this.visitId,
        deviceType: this.deviceType,
        os: this.os,
        browser: this.browser,
        cookie: navigator.cookieEnabled,
        message: message,
        method: this.method,
        path: window.location.href,
        referer: document.referrer
      })
    };

    try {
      if (window.ga) {
        window.ga('send', eventParams);
        console.warn('Sent ' + eventName + ' to GA', eventParams);
      } else {
        console.warn('ga is not defined', eventName, eventParams);
      }
    } catch (e) {
      console.error('Sending JS Exception to GA failed', e);
    }
  }

  sendAhoy(kind, message) {
    if (this.controllerAction !== 'home#new') {
      return;
    }

    var eventName = 'JS Exception (' + kind + ')';
    var eventParams = {
      os: this.os,
      browser: this.browser,
      cookie: navigator.cookieEnabled,
      message: message,
      method: this.method,
      path: window.location.href,
      referer: document.referrer
    };

    try {
      if (ahoy) {
        ahoy.track(eventName, eventParams);
        console.warn('Sent ' + eventName + ' to Ahoy', eventParams);
      } else {
        console.warn('ahoy is not defined', eventName, eventParams);
      }
    } catch (e) {
      console.error('Sending JS Exception to ahoy failed', e);
    }
  }
}

window.ErrorHandler = ErrorHandler;
