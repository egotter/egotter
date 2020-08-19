class Cache {
  constructor(ttl) {
    this.ttl = ttl || 259200; // 3 days
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

    if (this.time() - payload['time'] < this.ttl) {
      value = payload['value'];
    } else {
      this.delete(key);
    }

    return value;
  }

  write(key, value) {
    var payload = JSON.stringify({time: this.time(), value: value});
    this.storage[key] = payload;
  }

  delete(key) {
    this.storage[key] = null;
  }

  remaining(key) {
    try {
      return this.ttl - (this.time() - JSON.parse(this.storage[key])['time']);
    } catch (err) {
      return null;
    }
  }

  time() {
    return Math.floor(new Date().getTime() / 1000);
  }
}

window.Egotter['Cache'] = Cache;
