class EventTracker {
  constructor(attrs) {
    this.userId = attrs['userId'];
    this.deviceType = attrs['deviceType'];
    this.controllerAction = attrs['controllerAction'];
    this.via = attrs['via'];

    var self = this;

    window.trackPageEvents = function (pageName, eventName, eventParams) {
      self.track(pageName, eventName, eventParams);
    };

    window.trackMessageEvent = function (eventName) {
      self.trackMessageEvent(eventName);
    };

    window.trackDetectionEvent = function (eventName) {
      self.trackDetectionEvent(eventName);
    };

    window.trackModalEvent = function (eventName, eventAction) {
      self.trackModalEvent(eventName, eventAction);
    };

    window.trackTwitterLink = function (eventLocation, eventAction) {
      self.trackTwitterLink(eventLocation, eventAction);
    };
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
    var params = {url: window.location.href, page: window.location.pathname, via: this.via};
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

  trackModalEvent(eventName, eventAction) {
    if (!eventAction) {
      eventAction = 'opened';
    }

    ga('send', {
      hitType: 'event',
      eventCategory: 'Modal events',
      eventAction: eventName + ' ' + eventAction + ' / ' + this.controllerAction,
      eventLabel: JSON.stringify({userId: this.userId, deviceType: this.deviceType})
    });
    ahoy.track(eventName, {action: eventAction, page: window.location.href});
  }

  trackTwitterLink(eventLocation, eventAction) {
    var eventCategory = 'See on Twitter';

    ga('send', {
      hitType: 'event',
      eventCategory: eventCategory,
      eventAction: this.controllerAction + ' / ' + eventLocation + ' ' + eventAction,
      eventLabel: JSON.stringify({userId: this.userId, deviceType: this.deviceType})
    });
    ahoy.track(eventCategory, {page: window.location.href, location: eventLocation, action: eventAction});
  }
}

window.EventTracker = EventTracker;
