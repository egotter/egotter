class Cache {
  constructor() {
    this.data = {};
  }

  read(params) {
    var key = JSON.stringify(params);
    return this.data[key];
  }

  write(params, entry) {
    var key = JSON.stringify(params);
    this.data[key] = entry;
  }
}

class Fetcher {
  fetch(url, params) {
    var self = this;
    return new Promise(function (resolve, reject) {
      $.getJSON(url, params).done(function (res) {
        logger.log(self.constructor.name, 'done', res);
        resolve(res);
      }).fail(function (xhr, textStatus, errorThrown) {
        showErrorMessage(xhr, textStatus, errorThrown);
        reject(xhr);
      });
    });
  }
}

class FetchTask {
  constructor(url, uid, options, callback) {
    this.url = url;
    this.uid = uid;
    this.maxSequence = 0;
    this.limit = options['limit'];
    this.minLimit = options['limit'];
    this.maxLimit = options['maxLimit'];
    this.loading = false;
    this.template = window.templates['userRectangle'];
    this.callback = callback;
    this.cache = new Cache();
  }

  reset(options) {
    this.maxSequence = 0;
    this.limit = this.minLimit;
    if ('sortOrder' in options) {
      this.sortOrder = options['sortOrder'];
    }
    if ('filter' in options) {
      this.filter = options['filter'];
    }
  }

  fetch() {
    if (this.maxSequence === -1) {
      return;
    }

    if (this.loading) {
      return;
    }
    this.loading = true;

    var params = {
      uid: this.uid,
      limit: this.limit,
      max_sequence: this.maxSequence,
      sort_order: this.sortOrder,
      filter: this.filter,
    };

    logger.log('fetch params', params);

    var self = this;

    var responseReceived = function (res) {
      self.updateState(res);
      var users = self.renderUsers(res);

      if (self.callback) {
        var state = {loaded: true, completed: self.maxSequence === -1};
        self.callback(users, state);
      }
    };

    var res = this.cache.read(params);
    if (res) {
      logger.log('response[CACHE]', res);
      responseReceived(res);
    } else {
      new Fetcher().fetch(this.url, params).then(function (res) {
        logger.log('response', res);
        self.cache.write(params, res);
        responseReceived(res);
      });
    }
  }

  updateState(res) {
    if (res.max_sequence && res.max_sequence >= 0) {
      this.maxSequence = res.max_sequence + 1;
      this.limit = this.maxLimit;
    } else {
      this.maxSequence = -1;
    }

    this.loading = false;
  }

  renderUsers(res) {
    if (!res.users || res.users.length <= 0) {
      return [];
    }

    var self = this;
    var users = [];

    res.users.forEach(function (user) {
      var rendered = MustacheUtil.renderUser(self.template, user);
      users.push(rendered);
    });

    return users;
  }
}

window.FetchTask = FetchTask;
