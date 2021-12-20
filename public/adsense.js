(function () {
  var div = document.createElement('div');
  div.id = 'poinpgwawoiwoignsdoa';
  div.className = 'ads ad adsbox doubleclick ad-placement carbon-ads pub_300x250 pub_300x250m pub_728x90 text-ad textAd text_ad text_ads text-ads text-ad-links';
  div.innerHTML = '&nbsp;';
  div.style.display = 'none';
  document.body.appendChild(div);

  var url = 'https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js';
  var xhr = new XMLHttpRequest();
  xhr.open('GET', url, true);

  xhr.onerror = function () {
    logger.warn('adsbygoogle.js is not loaded.');
    window.adBlockerDetected = true;
  };

  xhr.send('');
})();

$(function () {
  var h = $('.adsense-container').height();
  $('.adsense-height').text(h);
});
