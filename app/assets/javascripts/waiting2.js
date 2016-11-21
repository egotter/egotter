'use strict';

var _createClass = function () { function defineProperties(target, props) { for (var i = 0; i < props.length; i++) { var descriptor = props[i]; descriptor.enumerable = descriptor.enumerable || false; descriptor.configurable = true; if ("value" in descriptor) descriptor.writable = true; Object.defineProperty(target, descriptor.key, descriptor); } } return function (Constructor, protoProps, staticProps) { if (protoProps) defineProperties(Constructor.prototype, protoProps); if (staticProps) defineProperties(Constructor, staticProps); return Constructor; }; }();

function _classCallCheck(instance, Constructor) { if (!(instance instanceof Constructor)) { throw new TypeError("Cannot call a class as a function"); } }

function waiting2(checkLogPath, pageCachePath, pageCachesPath, createdAt, scope) {
  var Cache = function () {
    function Cache() {
      _classCallCheck(this, Cache);
    }

    _createClass(Cache, [{
      key: 'setHash',
      value: function setHash(hash) {
        this.hash = hash;
      }
    }, {
      key: 'delete',
      value: function _delete() {
        return $.ajax({ url: pageCachePath.replace(/HASH/, this.hash), type: 'DELETE' });
      }
    }, {
      key: 'create',
      value: function create() {
        return $.post(pageCachesPath);
      }
    }]);

    return Cache;
  }();

  var Interval = function () {
    function Interval() {
      _classCallCheck(this, Interval);

      this.value = 2000;
      this.max = 5000;
    }

    _createClass(Interval, [{
      key: 'current',
      value: function current() {
        return this.value;
      }
    }, {
      key: 'next',
      value: function next() {
        this.value += 2000;
        if (this.value > this.max) this.value = this.max;
        return this.value;
      }
    }]);

    return Interval;
  }();

  var Retry = function () {
    function Retry() {
      _classCallCheck(this, Retry);

      this.count = 0;
      this.max = 5;
    }

    _createClass(Retry, [{
      key: 'current',
      value: function current() {
        return this.count;
      }
    }, {
      key: 'next',
      value: function next() {
        this.count += 1;
        return this.count < this.max;
      }
    }]);

    return Retry;
  }();

  var refreshBox = $('.alert.alert-info');
  refreshBox.find('a').on('click', function (e) {
    e.preventDefault();
    e.stopPropagation();

    cache.delete()
        .then(cache.create(), failed)
        .done(function () { window.location.reload() })
        .fail(failed);

    return false;
  });

  var interval = new Interval();
  var retry = new Retry();
  var cache = new Cache();

  function failed(xhr) {
    console.log(xhr.responseText);
  }

  function done(res, text_status, xhr) {
    console.log(res, text_status, xhr.status, interval.current(), retry.current());

    if (xhr.status === 200) {
      console.log(createdAt, res.created_at);
      if (createdAt < res.created_at) {
        cache.setHash(res.hash);
        refreshBox.show();
        refreshBox.sticky({topSpacing: 0});
      } else {
        console.log('do nothing.');
      }

      return;
    }

    if (!retry.next()) {
      console.log('stop waiting.');
      Rollbar.scope(scope).warning("Retries exhausted while attempting fetching.");
    } else {
      setTimeout(tic, interval.next());
    }
  }

  function tic() {
    $.get(checkLogPath).done(done).fail(failed);
  }

  tic();
}
