class AdBlockDetector {
  constructor(token) {
    this.token = token;
  }

  detect(callback) {
    if (window.adBlockerDetected || !document.getElementById(this.token)) {
      logger.log('Blocking Ads: Yes', window.adBlockerDetected);
      callback();
    } else {
      logger.log('Blocking Ads: No', window.adBlockerDetected);
    }
  }
}

window.AdBlockDetector = AdBlockDetector;
