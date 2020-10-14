var Level = {
  debug: 0,
  info: 1,
  warn: 2,
  error: 3,
};

class Logger {
  constructor(env) {
    this.env = env;
    this.level = null;

    if (env === 'production') {
      this.level = Level.warn;
    } else {
      this.level = Level.debug;
    }
  }

  log(...args) {
    if (this.level <= Level.debug) {
      console.log.apply(this, args);
    }
  }

  warn(...args) {
    if (this.level <= Level.warn) {
      console.warn.apply(this, args);
    }
  }

  error(...args) {
    if (this.level <= Level.error) {
      console.error.apply(this, args);
    }
  }
}

window.Logger = Logger;
