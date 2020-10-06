class Announcement {
  constructor(url, id) {
    this.url = url;
    this.id = id;
    this.load();
  }

  load() {
    var url = this.url;
    var id = '#' + this.id;
    new AsyncLoader(url, id).lazyload();
  }
}

window.Announcement = Announcement;
