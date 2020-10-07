class Announcements {
  constructor(url, id, callback) {
    this.url = url;
    this.id = id;
    this.load(callback);
  }

  load(callback) {
    var url = this.url;
    var id = '#' + this.id;
    new AsyncLoader(url, id, callback).lazyload();
  }
}

window.Announcements = Announcements;
