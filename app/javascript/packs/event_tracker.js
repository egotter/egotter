class EventTracker {
  constructor(attrs) {
    this.userId = attrs['userId'];
    this.deviceType = attrs['deviceType'];
    this.controllerAction = attrs['controllerAction'];
  }

  track(pageName, eventName, eventParams) {
    this.trackGoogleAnalytics(pageName, eventName, eventParams);
    this.trackAhoy(pageName, eventName, eventParams);
  }

  trackGoogleAnalytics(pageName, eventName, eventParams) {
    var params = {user_id: this.userId, deviceType: this.deviceType};
    if (eventParams) {
      params = Object.assign(params, eventParams);
    }
    ga('send', {
      hitType: 'event',
      eventCategory: pageName,
      eventAction: eventName + ' / ' + this.controllerAction,
      eventLabel: JSON.stringify(params)
    });
  }

  trackAhoy(pageName, eventName, eventParams) {
    var params = {page: window.location.href};
    if (eventParams) {
      params = Object.assign(params, eventParams);
    }
    ahoy.track(pageName + ' / ' + eventName, params);
  }

  trackMessageEvent(eventName) {
    ga('send', {
      hitType: 'event',
      eventCategory: 'Message events',
      eventAction: eventName + ' / ' + this.controllerAction,
      eventLabel: JSON.stringify({userId: this.userId, deviceType: this.deviceType})
    });
    ahoy.track(eventName, {page: window.location.href});
  }

  trackDetectionEvent(eventName) {
    this.trackMessageEvent(eventName);
  }

  trackModalEvent(eventName) {
    this.trackMessageEvent(eventName);
  }
}

window.EventTracker = EventTracker;
