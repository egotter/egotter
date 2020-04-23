class SnackMessage {
  static options = {
    actionText: '&times;',
    actionTextColor: '#777',
    backgroundColor: '#fff',
    pos: 'top-center',
    customClass: 'shadow',
    duration: 7500
  };

  constructor() {
  }

  static success(message) {
    var options = Object.assign({text: '<div class="text-primary">' + message + '</div>'}, this.options);
    Snackbar.show(options);
  }

  static alert(message) {
    var options = Object.assign({text: '<div class="text-danger">' + message + '</div>'}, this.options);
    Snackbar.show(options);
  }
}

window.SnackMessage = SnackMessage;
