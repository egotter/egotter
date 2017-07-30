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
