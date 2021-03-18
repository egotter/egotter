class EventTracker {
  constructor(attrs) {
    this.userId = attrs['userId'];
    this.deviceType = attrs['deviceType'];
    this.controllerAction = attrs['controllerAction'];
  }

  track(pageName, eventName, eventParams) {
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
    ahoy.track(eventName, params);
  }
}

window.EventTracker = EventTracker;
