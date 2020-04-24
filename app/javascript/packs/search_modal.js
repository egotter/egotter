'use strict';

class SearchModal {
  constructor(id) {
    var $modal = $('#' + id);
    var url = $modal.data('url');

    $modal.on('show.bs.modal', function () {
      if (!$modal.data('loaded')) {
        $modal.data('loaded', true);

        $.get(url).done(function (res) {
          console.log(url, 'loaded');
          $modal.find('.twitter.users').append(res);
        }).fail(function () {
          console.warn(url, 'failed');
          $modal.find('.twitter.users').append('Error');
        });
      }

      ga('send', {
        hitType: 'event',
        eventCategory: 'SearchModal',
        eventAction: 'show',
        eventLabel: 'SearchModal shown'
      });
    });

    $modal.on('shown.bs.modal', function (e) {
      $(e.target).find('input').focus();
    });
  }
}

window.SearchModal = SearchModal;
