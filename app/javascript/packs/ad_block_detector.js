class AdBlockDetector {
  constructor(token) {
    this.token = token;
  }

  detect(callback) {
    if (document.getElementById(this.token)) {
      logger.log('Blocking Ads: No');
    } else {
      logger.log('Blocking Ads: Yes');
      callback();
    }
  }
}

window.AdBlockDetector = AdBlockDetector;
