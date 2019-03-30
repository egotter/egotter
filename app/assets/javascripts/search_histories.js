'use strict';

var SearchHistories = {};

SearchHistories.initializeSearchModal = function () {
  var $modal = $('#search-modal');

  $modal.on('show.bs.modal', function (e) {
    if (!$modal.data('loaded')) {
      $modal.data('loaded', true);

      var url = $modal.data('url');
      $.get(url).done(function (res) {
        console.log(url, 'loaded');
        $modal.find('.twitter.users').append(res);
      });
    }
  });

  $modal.on('shown.bs.modal', function (e) {
    $(e.target).find('input').focus();
  });
};
