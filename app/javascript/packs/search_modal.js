class SearchModal {
  constructor(url, modalId, i18n, eventAction) {
    this.url = url;
    this.i18n = i18n;
    this.eventAction = eventAction;

    var $modal = this.$modal = $('#' + modalId);
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

    window.trackModalEvent('SearchModal');
  }

  load() {
    var url = this.url;
    var $modal = this.$modal;
    var i18n = this.i18n;

    $.get(url).done(function (res) {
      logger.log(url, 'loaded');

      if (res.modal_body) {
        $modal.find('.modal-body').append(res.modal_body);
      }

      if (res.users) {
        var container = $modal.find('#search-histories-users-container');
        var template = window.templates['searchHistoryRectangle'];
        container.empty();

        res.users.forEach(function (user) {
          var rendered = Mustache.render(template, user);
          container.append(rendered);
        });
      }
    }).fail(function (xhr) {
      logger.warn(url, xhr.responseText);
      var container = $modal.find('#search-histories-users-container');
      container.empty();
      container.append(i18n['failed']);
    });
  }
}

window.SearchModal = SearchModal;
