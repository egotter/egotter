'use strict';

class Cache {
  constructor() {
    this.ttl = 259200; // 3 days
    this.storage = window['sessionStorage'] || {};
  }

  read(key) {
    var entity = this.storage[key];
    if (!entity) {
      return null;
    }

    var payload = null;
    try {
      payload = JSON.parse(entity);
    } catch (err) {
      return null;
    }

    var value = null;

    if (this.current_time() - payload['time'] < this.ttl) {
      value = payload['value'];
    } else {
      this.delete(key);
    }

    return value;
  }

  write(key, value) {
    var payload = JSON.stringify({time: this.current_time(), value: value});
    this.storage[key] = payload;
  }

  delete(key) {
    this.storage[key] = null;
  }

  current_time() {
    return Math.floor(new Date().getTime() / 1000);
  }
}

window.Egotter['Cache'] = Cache;
