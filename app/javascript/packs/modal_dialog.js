class SearchModal {
  constructor(id, errorMessage) {
    var $modal = $('#' + id);
    var url = $modal.data('url');

    $modal.on('show.bs.modal', function () {
      if (!$modal.data('loaded')) {
        $modal.data('loaded', true);
        var container = $modal.find('#search-histories-users-container');

        $.get(url).done(function (res) {
          console.log(url, 'loaded', res.users.length);
          var template = window.templates['userRectangle'];
          container.empty();

          res.users.forEach(function (user) {
            var rendered = Mustache.render(template, user);
            container.append(rendered);
          });
        }).fail(function (xhr) {
          console.warn(url, xhr.responseText);
          container.empty();
          container.append(errorMessage);
        });
      }

      ga('send', {
        hitType: 'event',
        eventCategory: 'SearchModal',
        eventAction: 'show',
        eventLabel: 'SearchModal shown'
      });
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
