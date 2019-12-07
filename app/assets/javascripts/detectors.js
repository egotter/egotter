'use strict';

var Detectors = {};

Detectors.secretMode = function () {
  if ('storage' in navigator && 'estimate' in navigator.storage) {
    navigator.storage.estimate().then(function (estimate) {
      var usage = estimate.usage;
      var quota = estimate.quota;

      if (quota < 120000000) {
        console.log('Incognito');
        ga('send', {
          hitType: 'event',
          eventCategory: 'SecretMode found',
          eventAction: 'found',
          eventLabel: 'found'
        });
      } else {
        console.log('Not Incognito')
      }
    });
  } else {
    console.log('Can not detect');
  }
};
