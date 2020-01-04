'use strict';

var Detectors = {};

Detectors.secretMode = function (detected) {
  if ('storage' in navigator && 'estimate' in navigator.storage) {
    navigator.storage.estimate().then(function (estimate) {
      var usage = estimate.usage;
      var quota = estimate.quota;

      if (quota < 120000000) {
        console.log('Incognito');
        detected(quota);
      } else {
        console.log('Not Incognito')
      }
    });
  } else {
    console.log('Can not detect');
  }
};

Detectors.secretMode_old = function () {
  var fs = window.RequestFileSystem || window.webkitRequestFileSystem;
  if (fs) {
    fs(window.TEMPORARY,
        100,
        function (fs) {
          console.log('Not Incognito')
        },
        function (fe) {
          console.log('Incognito');
        });
  } else {
    console.log('Can not detect');
  }
};

Detectors.adBlocker = function (detected) {
  if (document.getElementById('poinpgwawoiwoignsdoa')) {
    console.log('Blocking Ads: No');
  } else {
    console.log('Blocking Ads: Yes');
    detected();
  }
};
