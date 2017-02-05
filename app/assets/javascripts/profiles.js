function enableSlickOnModal() {
  $('.profile-overview-modal').one('shown.bs.modal', function (e) {
    enableSlickNow($(this).find('.profile-overview-carousel'));
  });
}

function enableSlickNow(container) {
  container.slick({
    accessibility: false,
    arrows: false,
    dots: true,
    infinite: false
  });

  container.find('.description').show();
  container.find('.location').show();
  container.find('.link').show();
  container.find('.calendar').show();
}

function enableSlickOnPageTop() {
  var elem = $('.profile-overview-carousel:first');
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