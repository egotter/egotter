'use strict';

var SnackMessage = {};

SnackMessage.options = {
  actionText: '&times;',
  actionTextColor: '#777',
  backgroundColor: '#fff',
  pos: 'top-center',
  customClass: 'shadow',
  duration: 7500
};

SnackMessage.success = function (message) {
  var options = Object.assign({text: '<div class="text-primary">' + message + '</div>'}, this.options);
  Snackbar.show(options);
}

SnackMessage.alert = function (message) {
  var options = Object.assign({text: '<div class="text-danger">' + message + '</div>'}, this.options);
  Snackbar.show(options);
}
