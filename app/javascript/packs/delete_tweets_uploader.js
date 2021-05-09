class DeleteTweetsUploader {
  constructor(btnId, inputId, options, i18n) {
    this.$btn = $('#' + btnId);
    this.$input = $('#' + inputId);
    this.options = options;
    this.i18n = i18n;
    var self = this;

    this.$btn.on('click', function () {
      self.$input.trigger('click');
      return false;
    });

    this.$input.on('change', function () {
      self.$btn.prop('disabled', true).addClass('disabled');
      var file = self.$input[0].files[0];
      self.file = file;

      if (self.validate(file)) {
        self.upload(file);
      } else {
        self.$input[0].value = '';
        self.$btn.prop('disabled', false).removeClass('disabled');
      }
    });
  }

  validate(file) {
    var self = this;
    var valid = true;
    var error;

    if (!file.name.match(/^twitter-20\d{2}-\d{2}-\d{2}-[a-z0-9-]+.zip$/i)) {
      error = 'invalidFilename';
      valid = false;
    } else if (file.type.indexOf('zip') === -1 && file.type.indexOf('octet-stream' === -1)) {
      error = 'invalidContentType';
      valid = false;
    } else if (file.size < 1000000) { // 1MB
      error = 'filesizeTooSmall';
      valid = false;
    } else if (file.size > 30000000000) { // 30GB
      error = 'filesizeTooLarge';
      valid = false;
    }

    if (!valid) {
      self.showMessage(self.i18n[error]);
    }

    return valid;
  }

  upload(file) {
    var i18n = this.i18n;
    this.completed = false;
    var self = this;

    window.onbeforeunload = function () {
      if (!self.completed) {
        return i18n['alertOnBeforeunload'];
      }
    };

    this.showMessage(i18n['preparing']);

    this.uploadFile(file);

    // this.createPresignedUrl(file, function (url) {
    //   self.readFile(file, function (data) {
    //     self.uploadChunk(url, data);
    //   });
    // });
  }

  uploadFile(file) {
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
          self.showMessage(i18n['uploading'].replace('{value}', value + '%'));
        }
      };
    })();

    AWS.config.region = 'ap-northeast-1';
    AWS.config.credentials = new AWS.CognitoIdentityCredentials({
      IdentityPoolId: this.options.IdentityPoolId,
    });

    self.metadata = {
      filename: file.name,
      filesize: '' + file.size,
      filetype: file.type,
      since: $('#premium_since_date').val(),
      until: $('#premium_until_date').val()
    };
    logger.log(self.metadata);

    var upload = new AWS.S3.ManagedUpload({
      params: {
        Bucket: this.options.bucket,
        Key: this.options.key,
        Body: file,
        ACL: 'private',
        Metadata: self.metadata
      }
    });

    var promise = upload.on('httpUploadProgress', onProgress).promise();

    promise.then(
        function () {
          self.completed = true;
          self.notifyUploadCompleted(self.metadata);
          self.showMessage(i18n['success']);
        },
        function (err) {
          logger.error(err.message);
          self.showMessage(i18n['fail']);
        }
    );
  }

  // TODO Remove
  // readFile(file, callback) {
  //   var i18n = this.i18n;
  //   var offset = 0;
  //   var size = 10_000_000_000; // 10GB
  //   var reader = new FileReader();
  //
  //   var readChunk = function () {
  //     var slice = file.slice(offset, offset + size, file.type);
  //     offset += size;
  //     reader.readAsArrayBuffer(slice);
  //   };
  //
  //   reader.onload = function (e) {
  //     callback(e.target.result);
  //     if (offset >= file.size) {
  //       logger.log('#readFile completed');
  //     } else {
  //       readChunk();
  //     }
  //   };
  //
  //   reader.onerror = function (e) {
  //     logger.error(e.target.error.name);
  //     ToastMessage.warn(i18n['fail'], {autohide: false});
  //   };
  //
  //   readChunk();
  // }

  // TODO Remove
  // uploadChunk(url, data) {
  //   var i18n = this.i18n;
  //   var self = this;
  //
  //   var onProgress = (function () {
  //     var value = 0;
  //     return function (e) {
  //       if (self.completed) {
  //         return;
  //       }
  //
  //       if (e.lengthComputable) {
  //         value = Math.floor(100 * e.loaded / e.total);
  //       } else {
  //         value += Math.floor(Math.random() * 6); // 0-5
  //         if (value > 99) {
  //           value = 99;
  //         }
  //       }
  //       ToastMessage.info(i18n['uploading'].replace('{value}', value + '%'), {autohide: false});
  //     };
  //   })();
  //
  //   $.ajax({
  //     url: url,
  //     data: data,
  //     type: 'PUT',
  //     xhr: function () {
  //       var xhr = new window.XMLHttpRequest();
  //       xhr.upload.addEventListener('progress', onProgress, false);
  //       return xhr;
  //     },
  //     processData: false,
  //     contentType: false
  //   }).done(function () {
  //     self.completed = true;
  //     self.notifyUploadCompleted();
  //     ToastMessage.info(i18n['success'], {autohide: false});
  //   }).fail(function () {
  //     ToastMessage.warn(i18n['fail'], {autohide: false});
  //   });
  // }

  // TODO Remove
  // createPresignedUrl(file, callback) {
  //   var url = '/api/v1/delete_tweets_presigned_urls'; //  api_v1_delete_tweets_presigned_urls_path
  //   $.post(url, {filename: file.name, filesize: file.size}).done(function (res) {
  //     callback(res.url);
  //   }).fail(showErrorMessage);
  // }

  notifyUploadCompleted(metadata) {
    var url = '/api/v1/delete_tweets_notifications'; //  api_v1_delete_tweets_notifications_path
    $.post(url, metadata).done(function () {
    }).fail(showErrorMessage);
  }

  showMessage(message) {
    if (this.file) {
      try {
        message = message
            .replace('{name}', this.escapeHtml(this.file.name))
            .replace('{type}', this.escapeHtml(this.file.type))
            .replace('{size}', this.escapeHtml('' + this.file.size));
      } catch (e) {
        console.error(e);
      }
    }

    ToastMessage.info(message, {autohide: false});
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

window.DeleteTweetsUploader = DeleteTweetsUploader;
