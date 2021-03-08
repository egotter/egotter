class SecretModeDetector {
  detect(callback) {
    this.detectByStorageQuota(callback);
    this.detectByFileSystem(callback);
  }

  detectByStorageQuota(callback) {
    if ('storage' in navigator && 'estimate' in navigator.storage) {
      navigator.storage.estimate().then(function (estimate) {
        // var usage = estimate.usage;
        var quota = estimate.quota;

        if (quota < 120000000) {
          logger.log('detectByStorageQuota: Incognito');
          callback(quota);
        } else {
          logger.log('detectByStorageQuota: Not Incognito', quota);
        }
      });
    } else {
      // This feature is available only in secure contexts (HTTPS)
      logger.log('detectByStorageQuota: Can not detect');
    }
  }

  detectByFileSystem(callback) {
    var fs = window.RequestFileSystem || window.webkitRequestFileSystem;
    if (fs) {
      fs(window.TEMPORARY,
          100,
          function () {
            logger.log('detectByFileSystem: Not Incognito');
          },
          function () {
            logger.log('detectByStorageQuota: Incognito');
            callback();
          });
    } else {
      logger.log('detectByStorageQuota: Can not detect');
    }
  }
}

window.SecretModeDetector = SecretModeDetector;
