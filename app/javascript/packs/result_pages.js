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
        console.log(self.constructor.name, 'done', res);
        resolve(res);
      }).fail(function (xhr) {
        console.log(self.constructor.name, 'fail', xhr.responseText);
        reject(xhr);
      });
    });
  }
}

class FetchTask {
  constructor(url, uid, options) {
    this.url = url;
    this.uid = uid;
    this.maxSequence = 0;
    this.limit = options['limit'];
    this.minLimit = options['limit'];
    this.maxLimit = options['maxLimit'];
    this.sortOrder = options['sortOrder'];
    this.filter = options['filter'];
    this.gridClass = options['gridClass'];
    this.insertAd = options['insertAd'];
    this.loading = false;

    this.$placeholders = $('.placeholders-wrapper');
    this.$emptyPlaceholders = $('.empty-placeholders-wrapper');
    this.$usersContainer = $('.main-content.twitter.users');

    this.cache = new Cache();
  }

  reset(options, callback) {
    this.maxSequence = 0;
    this.limit = this.minLimit;
    if ('sortOrder' in options) {
      this.sortOrder = options['sortOrder'];
    }
    if ('filter' in options) {
      this.filter = options['filter'];
    }
    this.$placeholders.show();
    this.$usersContainer.empty();
    this.fetch(callback);
  }

  fetch(callback) {
    if (this.maxSequence === -1) {
      return;
    }

    if (this.loading) {
      return;
    }
    this.loading = true;

    var params = {
      uid: this.uid,
      html: 1,
      limit: this.limit,
      max_sequence: this.maxSequence,
      sort_order: this.sortOrder,
      filter: this.filter,
      grid_class: this.gridClass,
      insert_ad: this.insertAd
    };

    console.log('fetch params', params);

    var self = this;

    var update = function (res) {
      if (res.max_sequence && res.max_sequence >= 0) {
        self.maxSequence = res.max_sequence + 1;
        self.limit = self.maxLimit;
      } else {
        self.maxSequence = -1;
        // $seeMoreBtn.remove();
        // $seeAtOnceBtn.remove();
      }

      self.$placeholders.hide();
      var $users = $(res.users_html).hide().fadeIn(1000);
      self.$usersContainer.append($users);

      if (res.users.length > 0) {
        self.$emptyPlaceholders.hide();
      } else {
        self.$emptyPlaceholders.show();
      }

      self.loading = false;

      if (callback) {
        var state = {loaded: true, completed: self.maxSequence === -1};
        callback(state);
      }
    };

    var res = this.cache.read(params);
    if (res) {
      console.log('response[CACHE]', res);
      update(res);
    } else {
      new Fetcher().fetch(this.url, params).then(function (res) {
        console.log('response', res);
        self.cache.write(params, res);
        update(res);
      });
    }
  }
}

window.FetchTask = FetchTask;
