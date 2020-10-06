class Announcement {
  constructor(url, id) {
    this.url = url;
    this.id = id;
    this.load();
  }

  load() {
    var url = this.url;
    var id = '#' + this.id;

    new AsyncLoader(url, id, function (res) {
      var container = $( id);
      res.records.forEach(function (record) {
        var row = $('<tr>');
        row.append($('<td>').text(record.date));
        row.append($('<td>').text(record.message));
        container.append(row);
      });
    }).lazyload();
  }
}

window.Announcement = Announcement;
