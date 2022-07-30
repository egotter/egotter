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

class FetchTask {
  constructor(url, uid, options, callback, errCallback) {
    this.url = url;
    this.uid = uid;
    this.maxSequence = 0;
    this.limit = options['limit'];
    this.minLimit = options['limit'];
    this.maxLimit = options['maxLimit'];
    this.loading = false;
    this.template = window.templates['userRectangle'];
    this.callback = callback;
    this.errCallback = errCallback;
    this.cache = new Cache();
    this.errorCount = 0;
    this.retryLimit = 10;
    this.retryInterval = 3000;
  }

  reset(options) {
    this.maxSequence = 0;
    this.limit = this.minLimit;
    this.errorCount = 0;
    if ('sortOrder' in options) {
      this.sortOrder = options['sortOrder'];
    }
    if ('filter' in options) {
      this.filter = options['filter'];
    }
  }

  responseReceived(res) {
    this.updateState(res);
    var users = this.renderUsers(res);

    if (this.callback) {
      var state = {loaded: true, completed: this.maxSequence === -1};
      this.callback(users, state);
    }
  }

  errorReceived(xhr, textStatus, errorThrown) {
    var runCallback = false;

    if (xhr.status === 400) {
      logger.log('Bad request');
      showErrorMessage(xhr, textStatus, errorThrown);
      runCallback = true;
    } else if (xhr.status === 408) {
      if (++this.errorCount <= this.retryLimit) {
        logger.log('Retry fetching', this.errorCount);
        this.retryFetch();
      } else {
        logger.log('Retry exhausted');
        showErrorMessage(xhr, textStatus, errorThrown);
        runCallback = true;
      }
    } else {
      logger.log('Unknown error');
      showErrorMessage(xhr, textStatus, errorThrown);
      runCallback = true;
    }

    if (runCallback && this.errCallback) {
      this.errCallback();
    }
  }

  fetch() {
    if (this.loading) {
      return;
    }

    if (this.maxSequence === -1) {
      return;
    }

    this.loading = true;

    var params = {
      uid: this.uid,
      limit: this.limit,
      max_sequence: this.maxSequence,
      offset: this.maxSequence,
      sort_order: this.sortOrder,
      filter: this.filter
    };
    if (this.errorCount > 0) {
      params['error_count'] = this.errorCount;
    }

    logger.log('Start fetching', params);

    var self = this;

    var res = this.cache.read(params);
    if (res) {
      logger.log('response[CACHE]', res);
      self.responseReceived(res);
    } else {
      $.getJSON(this.url, params).done(function (res) {
        logger.log('Response received', res);
        self.cache.write(params, res);
        self.responseReceived(res);
      }).fail(function (xhr, textStatus, errorThrown) {
        logger.log('Error received');
        self.errorReceived(xhr, textStatus, errorThrown);
      });
    }
  }

  retryFetch() {
    var self = this;
    setTimeout(function () {
      self.loading = false;
      self.fetch();
    }, this.retryInterval);
  }

  updateState(res) {
    if (res.max_sequence && res.max_sequence >= 0) {
      this.maxSequence = res.max_sequence + 1;
      this.limit = this.maxLimit;
    } else {
      this.maxSequence = -1;
    }

    this.loading = false;
    this.errorCount = 0;
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
