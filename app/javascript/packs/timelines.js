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
      logger.warn(url, xhr.responseText);

      var message;
      try {
        message = JSON.parse(xhr.responseText)['message'];
      } catch (e) {
        logger.error(e);
      }
      if (!message) {
        message = xhr.status + ' (' + errorThrown + ')';
      }

      if (errorCallback) {
        errorCallback(message);
      }
    });
  }
}

window.FeedItem = FeedItem;
