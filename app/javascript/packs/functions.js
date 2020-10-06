class Functions {
  constructor(url, id) {
    this.url = url;
    this.id = id;
    this.load();
  }

  load(callback) {
    var url = this.url;
    var id = '#' + this.id;
    new AsyncLoader(url, id, callback).lazyload();
  }
}

window.Functions = Functions;
