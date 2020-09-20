class Announcement {
  constructor(url, id) {
    this.url = url;
    this.id = id;
    this.load();
  }

  load() {
    var url = this.url;
    var id = this.id;

    $.get(url).done(function (res) {
      console.log(url, 'loaded');

      var container = $('#' + id);

      res.records.forEach(function (record) {
        var row = $('<tr>');
        row.append($('<td>').text(record.date));
        row.append($('<td>').text(record.message));
        container.append(row);
      });
    }).fail(function (xhr) {
      console.warn(url, xhr.responseText);
    });
  }
}

window.Announcement = Announcement;
