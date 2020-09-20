class SearchModal {
  constructor(id, errorMessage) {
    this.errorMessage = errorMessage;
    var $modal = this.$modal = $('#' + id);
    this.url = $modal.data('url');
    var self = this;

    $modal.on('show.bs.modal', function () {
      self.show();
    });
  }

  show() {
    var $modal = this.$modal;

    if (!$modal.data('loaded')) {
      $modal.data('loaded', true);
      this.load();
    }

    ga('send', {
      hitType: 'event',
      eventCategory: 'SearchModal',
      eventAction: 'show',
      eventLabel: 'SearchModal shown'
    });
  }

  load() {
    var url = this.url;
    var $modal = this.$modal;
    var errorMessage = this.errorMessage;

    $.get(url).done(function (res) {
      console.log(url, 'loaded');

      if (res.modal_body) {
        $modal.find('.modal-body').append(res.modal_body);
      }

      if (res.users) {
        var container = $modal.find('#search-histories-users-container');
        var template = window.templates['userRectangle'];
        container.empty();

        res.users.forEach(function (user) {
          var rendered = Mustache.render(template, user);
          container.append(rendered);
        });
      }
    }).fail(function (xhr) {
      console.warn(url, xhr.responseText);
      var container = $modal.find('#search-histories-users-container');
      container.empty();
      container.append(errorMessage);
    });
  }
}

window.SearchModal = SearchModal;

class SignInModal {
  constructor(url) {
    var $el = $('#sign-in-modal');

    $el.find('.btn.positive').on('click', function () {
      window.location.href = url;
    });

    $el.modal();
  }
}

window.SignInModal = SignInModal;
