'use strict';

function enableSlickOnModal(uniqueId) {
  enableSlickOnPageTop(uniqueId);
}

function enableSlickOnPageTop(uniqueId) {
  const container = $('.profile-overview-container.' + uniqueId);
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

function enableSlickOnUserList(selector) {
  const option = {
    accessibility: false,
    arrows: false,
    dots: false,
    infinite: true
  };

  $(selector).find('.user-item-carousel').each(function () {
    var loaded = false;
    $(this)
        .lazyload()
        .on('appear', function () {
          if (loaded) return;
          loaded = true;

          $(this).slick(option);
          $(this)
              .find('img.lazy').trigger('appear').end()
              .find('.media.description-box').show().end()
              .find('.media.count-box').show().end()
              .find('.media.score-box').show();
        });
  });
}

function enableSlickOnSearchHistory(selector){
  const option = {
    accessibility: false,
    arrows: false,
    dots: false,
    infinite: true
  };

  const container = $(selector);
  container.find('.user-item-carousel.search-histories').slick(option);
  container.find('.media.description-box').show();
  container.find('.media.count-box').show();
  container.find('.media.score-box').show();
}

function setModalOpenLogger(selector, via, url) {
  $(selector).on('shown.bs.modal', function() {
    $.post(url, {via: via});
  });
}