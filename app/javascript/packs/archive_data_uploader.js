class ArchiveDataUploader {
  constructor(btnId, inputId, notifyUrl, options, i18n) {
    this.$btn = $('#' + btnId);
    this.$input = $('#' + inputId);
    this.notifyUrl = notifyUrl;
    this.options = options;
    this.i18n = i18n;
    this.errors = [];

    this.$btn.on('click', this.openFileSelector.bind(this));
    this.$input.on('change', this.fileSelected.bind(this));
  }

  openFileSelector() {
    this.$input.trigger('click');
    return false;
  }

  fileSelected() {
    this.$btn.prop('disabled', true).addClass('disabled');
    var file = new ArchiveFile(this.$input[0].files[0], this.i18n);

    if (file.validate()) {
      this.startUploading(file);
    } else {
      this.$input[0].value = '';
      this.$btn.prop('disabled', false).removeClass('disabled');
      showMessage(file.errorMessage(), file.attrs());
    }
  }

  startUploading(file) {
    var i18n = this.i18n;
    this.completed = false;
    var self = this;

    window.onbeforeunload = function () {
      if (!self.completed) {
        return i18n['alertOnBeforeunload'];
      }
    };

    showMessage(i18n['preparing'], file.attrs());

    setTimeout(function () {
      self.managedUpload(file).then(
          function () {
            self.completed = true;
            self.notifyUploadCompleted(self.metadata);
            showMessage(i18n['success']);
          },
          function (err) {
            logger.error(err.message);
            showMessage(i18n['fail'], file.attrs());
          }
      );
    }, 10000);
  }

  managedUpload(file) {
    var i18n = this.i18n;
    var self = this;

    var onProgress = (function () {
      var value = 0;
      return function (event) {
        if (self.completed) {
          return;
        }

        var curValue = parseInt((event.loaded * 100) / event.total);
        if (curValue > value) {
          value = curValue;
          var options = Object.assign({value: value + '%'}, file.attrs());
          showMessage(i18n['uploading'], options);
        }
      };
    })();

    AWS.config.region = 'ap-northeast-1';
    AWS.config.credentials = new AWS.CognitoIdentityCredentials({
      IdentityPoolId: this.options.IdentityPoolId,
    });

    var fileObj = file.getFile();

    self.metadata = {
      filename: fileObj.name,
      filesize: '' + fileObj.size,
      filetype: fileObj.type,
      since: $('#premium_since_date').val(),
      until: $('#premium_until_date').val()
    };
    logger.log(self.metadata);

    var upload = new AWS.S3.ManagedUpload({
      params: {
        Bucket: this.options.bucket,
        Key: this.options.key,
        Body: fileObj,
        ACL: 'private',
        Metadata: self.metadata
      }
    });

    return upload.on('httpUploadProgress', onProgress).promise();
  }

  notifyUploadCompleted(metadata) {
    $.post(this.notifyUrl, metadata).done(function () {
    }).fail(showErrorMessage);
  }
}

window.ArchiveDataUploader = ArchiveDataUploader;

class ArchiveFile {
  constructor(file, i18n) {
    this.file = file;
    this.i18n = i18n;
    this.errors = [];
  }

  validate() {
    var file = this.file;
    this.errors = [];

    if (!file.name.match(/^twitter-20\d{2}-\d{2}-\d{2}-[a-z0-9-]+.zip$/i)) {
      this.errors = ['invalidFilename'];
    } else if (file.type.indexOf('zip') === -1 && file.type.indexOf('octet-stream' === -1)) {
      this.errors = ['invalidContentType'];
    } else if (file.size < 1000000) { // 1MB
      this.errors = ['filesizeTooSmall'];
    } else if (file.size > 30000000000) { // 30GB
      this.errors = ['filesizeTooLarge'];
    }

    return this.errors.length === 0;
  }

  errorMessage() {
    if (this.errors.length === 0) {
      return;
    }

    var key = this.errors[0];
    var message = this.i18n[key];

    if (!message) {
      logger.warn('Message not found', key, message, this.errors);
      return key;
    }

    return message;
  }

  getFile() {
    return this.file;
  }

  attrs() {
    return {name: this.file.name, type: this.file.type, size: this.file.size};
  }

  escapeHtml(str) {
    if (str.length >= 30) {
      str = str.substr(0, 30) + '...';
    }

    var type = '';
    try {
      type = str.replace(/<\/?[^>]+(>|$)/g, '');
      if (!type) {
        type = 'empty';
      }
    } catch (e) {
      type = 'error';
    }
    return type;
  }
}


function showMessage(message, options) {
  if (options) {
    Object.keys(options).forEach(function (key) {
      message = message.replace('{' + key + '}', escapeHtml('' + options[key]));
    });
  }
  ToastMessage.info(message, {autohide: false});
}

function escapeHtml(str) {
  if (str.length >= 30) {
    str = str.substr(0, 30) + '...';
  }

  var type = '';
  try {
    type = str.replace(/<\/?[^>]+(>|$)/g, '');
    if (!type) {
      type = 'empty';
    }
  } catch (e) {
    type = 'error';
  }
  return type;
}
