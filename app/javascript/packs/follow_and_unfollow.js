class Twitter {
  constructor() {
  }

  follow(uid) {
    if (!uid) {
      console.warn('uid not found');
      ToastMessage.info('Follow is failed');
      return;
    }

    var url = '/follows'; // follows_path
    $.post(url, {uid: uid}).done(function (res) {
      console.log('follow done', res);
      ToastMessage.info(res.message);
    }).fail(function (xhr) {
      if (xhr.status === 429) { // Too many requests
        $('#follow-limitation-warning-modal').modal();
      } else {
        ToastMessage.warn('Follow is failed');
      }
    });
  }

  unfollow(uid) {
    if (!uid) {
      console.warn('uid not found');
      ToastMessage.info('Unfollow is failed');
      return;
    }

    var url = '/unfollows'; // unfollows_path
    $.post(url, {uid: uid}).done(function (res) {
      console.log('unfollow done', res);
      ToastMessage.info(res.message);
    }).fail(function (xhr) {
      if (xhr.status === 429) { // Too many requests
        $('#unfollow-limitation-warning-modal').modal();
      } else {
        ToastMessage.warn('Unfollow is failed');
      }
    });
  }
}

window.Twitter = Twitter;

class Modal {
  constructor(selector) {
    this.$el = $(selector);
    this.callback = null;
    var $el = this.$el;

    if (!$el.data('init')) {
      $el.find('.btn.positive').on('click', this.btnClicked.bind(this));
      $el.data('init', true);
    }
  }

  btnClicked() {
    this.$el.data('callback')();
    this.$el.modal('hide');
  }

  skipConfirmation() {
    return this.$el.find('.dont-confirm input').prop('checked');
  }

  setScreenName(value) {
    this.$el.find('.screen-name').text(value);
  }

  setCallback(fn) {
    this.$el.data('callback', fn);
  }

  show() {
    this.$el.modal();
  }
}

class FollowModal extends Modal {
  constructor() {
    super('#create-follow-modal');
  }
}

class UnfollowModal extends Modal {
  constructor() {
    super('#create-unfollow-modal');
  }
}

class Button {
  constructor(parent, child) {
    var self = this;
    $(parent).off('click', child);
    $(parent).on('click', child, function (e) {
      e.stopPropagation();
      self.click(e.target);
      return false;
    });
  }

  // Open follow/unfollow modal or do follow/unfollow
  click(target) {
    var $clicked = $(target);
    var self = this;

    if (this.modal.skipConfirmation()) {
      this.perform($clicked);
    } else {
      this.modal.setScreenName($clicked.data('screen-name'));
      this.modal.setCallback(function () {
        self.perform($clicked);
      });
      this.modal.show();
    }
  }

  perform() {
    throw new Error('NotImplemented');
  }
}

class FollowButton extends Button {
  constructor(selector) {
    super(selector, '.btn.no-follow');
    this.modal = new FollowModal();
  }

  perform($clicked) {
    new Twitter().follow($clicked.data('uid'));
    $clicked.hide().siblings('.btn.follow').show();
  }
}

window.FollowButton = FollowButton;

// Idempotent
class UnfollowButton extends Button {
  constructor(selector) {
    super(selector, '.btn.follow');
    this.modal = new UnfollowModal();
  }

  perform($clicked) {
    new Twitter().unfollow($clicked.data('uid'));
    $clicked.hide().siblings('.btn.no-follow').show();
  }
}

window.UnfollowButton = UnfollowButton;
