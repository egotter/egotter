function enableSlickOnModal() {
  var $modal = $('.profile-overview-modal');
  $modal.one('show.bs.modal', function (e) {
    var $m = $(this);
    setTimeout(function () { enableSlickNow($m.find('.profile-overview-carousel')) }, 500);
  });
}

function enableSlickNow(container) {
  container.slick({
    accessibility: false,
    arrows: false,
    dots: true,
    infinite: false
  });

  container.find('.profile-description').show();
  container.find('.profile-location').show();
  container.find('.profile-link').show();
  container.find('.profile-calendar').show();
}

function enableSlickOnPageTop() {
  var elem = $('.profile-overview-carousel');
  if (elem.is(':visible')) {
    enableSlickNow(elem);
  } else {
    console.log('Visible ".profile-overview-carousel" is not found.');
  }
}

function setModalOpenLogger(via, url) {
  $('.profile-overview-modal').on('shown.bs.modal', function() {
    $.post(url, {via: via});
  });
}