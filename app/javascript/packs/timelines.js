class FeedItem {
  constructor(url, successCallback, errorCallback) {
    this.url = url;
    this.successCallback = successCallback;
    this.errorCallback = errorCallback;
    this.fetch();
  }

  fetch() {
    var url = this.url;
    var successCallback = this.successCallback;
    var errorCallback = this.errorCallback;

    $.get(url).done(function (res) {
      logger.log(url, res);
      successCallback(res);
    }).fail(function (xhr, textStatus, errorThrown) {
      if (errorCallback) {
        errorCallback(showErrorMessage(xhr, textStatus, errorThrown));
      }
    });
  }
}

window.FeedItem = FeedItem;
