class Twitter {
  constructor(via) {
    this.follow_url = '/api/v1/follow_requests?via=' + via; // api_v1_follow_requests_path
    this.unfollow_url = '/unfollows?via=' + via; // unfollows_path
  }

  follow(uid) {
    if (!uid) {
      logger.warn('There is no uid');
      ToastMessage.warn('There is no uid');
      return;
    }

    var url = this.follow_url;

    $.post(url, {uid: uid}).done(function (res) {
      logger.log('follow done', res);
      ToastMessage.info(res.message);
    }).fail(function (xhr, textStatus, errorThrown) {
      if (xhr.status === 429) { // Too many requests
        $('#follow-limitation-warning-modal').modal();
      } else {
        showErrorMessage(xhr, textStatus, errorThrown);
      }
    });
  }

  unfollow(uid) {
    if (!uid) {
      logger.warn('There is no uid');
      ToastMessage.warn('There is no uid');
      return;
    }

    var url = this.unfollow_url;

    $.post(url, {uid: uid}).done(function (res) {
      logger.log('unfollow done', res);
      ToastMessage.info(res.message);
    }).fail(function (xhr, textStatus, errorThrown) {
      if (xhr.status === 429) { // Too many requests
        $('#unfollow-limitation-warning-modal').modal();
      } else {
        showErrorMessage(xhr, textStatus, errorThrown);
      }
    });
  }
}

window.Twitter = Twitter;
