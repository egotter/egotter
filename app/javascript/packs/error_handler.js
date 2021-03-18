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
    var eventLabel = {
      userId: this.userId,
      visitId: this.visitId,
      deviceType: this.deviceType,
      os: this.os,
      browser: this.browser,
      cookie: navigator.cookieEnabled,
      message: message,
      path: window.location.href,
      referer: document.referrer
    };

    var eventParams = {
      hitType: 'event',
      eventCategory: 'JS Exception',
      eventAction: kind + ' / ' + this.controllerAction,
      eventLabel: JSON.stringify(eventLabel)
    };

    try {
      if (ga) {
        ga('send', eventParams);
        console.warn('Sent JS Exception to GA', kind, message);
      } else {
        console.warn('ga() is not defined', kind, message);
      }
    } catch (e) {
      console.error('Sending JS Exception to GA is failed', e);
    }

    if (this.controllerAction === 'home#new') {
      ahoy.track('JS Exception (' + kind + ')', eventLabel);
    }
  }
}

window.ErrorHandler = ErrorHandler;
