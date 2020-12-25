class DeleteTweetsUploader {
  constructor(btnId, inputId, i18n) {
    this.$btn = $('#' + btnId);
    this.$input = $('#' + inputId);
    this.i18n = i18n;
    var self = this;

    this.$btn.on('click', function () {
      self.$input.trigger('click');
      return false;
    });

    this.$input.on('change', function () {
      self.$btn.prop('disabled', true).addClass('disabled');
      var file = self.$input[0].files[0];
      var valid = true;

      if (!file.name.match(/^twitter-20\d{2}-\d{2}-\d{2}-[a-z0-9-]+.zip$/i)) {
        ToastMessage.warn(self.i18n['invalidFilename']);
        valid = false;
      } else if (file.type.indexOf('zip') === -1 && file.type.indexOf('octet-stream' === -1)) {
        var message = self.i18n['invalidContentType'];
        ToastMessage.info(message.replace('{type}', self.escapeFileType(file.type)));
        valid = false;
      } else if (file.size > 30000000000) { // 30GB
        ToastMessage.warn(self.i18n['filesizeTooLarge']);
        valid = false;
      }

      if (valid) {
        self.upload(file);
      } else {
        self.$input[0].value = '';
        self.$btn.prop('disabled', false).removeClass('disabled');
      }
    });
  }

  upload(file) {
    var reader = new FileReader();
    var i18n = this.i18n;
    var completed = false;
    var self = this;

    window.onbeforeunload = function () {
      if (!completed) {
        return i18n['alertOnBeforeunload'];
      }
    };

    var updateProgress = (function () {
      var value = 0;
      return function (e) {
        if (completed) {
          return;
        }

        if (e.lengthComputable) {
          value = Math.floor(100 * e.loaded / e.total);
        } else {
          value += Math.floor(Math.random() * 6); // 0-5
          if (value > 99) {
            value = 99;
          }
        }
        ToastMessage.info(i18n['uploading'] + value + '%');
      };
    })();

    ToastMessage.info(i18n['preparing']);

    reader.onload = function (e) {
      self.createPresignedUrl(file, function (url) {
        $.ajax({
          url: url,
          data: e.target.result,
          type: 'PUT',
          xhr: function () {
            var xhr = new window.XMLHttpRequest();
            xhr.upload.addEventListener('progress', updateProgress, false);
            return xhr;
          },
          processData: false,
          contentType: false
        }).done(function () {
          completed = true;
          self.notifyUploadCompleted();
          ToastMessage.info(i18n['success']);
        }).fail(function () {
          ToastMessage.warn(i18n['fail']);
        });
      });
    };

    reader.readAsArrayBuffer(file);
  }

  createPresignedUrl(file, callback) {
    var url = '/api/v1/delete_tweets_presigned_urls'; //  api_v1_delete_tweets_presigned_urls_path
    $.post(url, {filename: file.name, filesize: file.size}).done(function (res) {
      callback(res.url);
    }).fail(showErrorMessage);
  }

  notifyUploadCompleted() {
    var url = '/api/v1/delete_tweets_notifications'; //  api_v1_delete_tweets_notifications_path
    $.post(url).done(function () {
    }).fail(showErrorMessage);
  }

  escapeFileType(str) {
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
