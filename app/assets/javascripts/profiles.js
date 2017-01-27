function enableSlickOnModalWithDelay(uniqueId) {
  $('.profile-overview-modal.' + uniqueId).one('show.bs.modal', function (e) {
    setTimeout(function () { enableSlickOnPageTop(uniqueId) }, 500);
  });
}

function enableSlickOnPageTop(uniqueId) {
  var container = $('.profile-overview-container.' + uniqueId);
  container.find('.profile-overview-carousel').slick({
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

function setModalOpenLogger(selector, via, url) {
  $(selector).on('shown.bs.modal', function() {
    $.post(url, {via: via});
  });
}