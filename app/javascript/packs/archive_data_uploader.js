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
      readTweetFiles(file.getFile()).then(function (data) {
        writeTweetFiles(data).then(function (newFile) {
          self.uploadFile(newFile, file.attrs()).then(function () {
            self.completed = true;
            self.notifyUploadCompleted(self.metadata, function () {
              showMessage(i18n['success']);
            }, function () {
              showMessage(i18n['duplicateFileUploaded'], file.attrs());
            });
          }).catch(function (err) {
            logger.warn('uploadFile() failed', err);
            showMessage(i18n['fail'], Object.assign({reason: err}, file.attrs()));
          });
        }).catch(function (err) {
          logger.warn('writeTweetFiles() failed', err);
          showMessage(i18n['fail'], Object.assign({reason: err}, file.attrs()));
        });
      }).catch(function (err) {
        logger.warn('readTweetFiles() failed', err);
        showMessage(i18n['brokenFile'], Object.assign({reason: err}, file.attrs()));
      });

    }, 10 * 1000);
  }

  uploadFile(fileObj, fileAttrs) {
    var i18n = this.i18n;
    var startTime = new Date();
    var AWS = window.AWS;
    var self = this;

    var onProgress = (function () {
      var value = 0;
      return function (event) {
        if (self.completed || !event.total) {
          return;
        }

        var curValue = Math.round(100 * event.loaded / event.total);

        if (curValue > value) {
          value = curValue;
          var loadedSize = Math.round(event.loaded / ((new Date() - startTime) / 1000));
          var options = Object.assign({percentage: value + '%', speed: readableSize(loadedSize)}, fileAttrs);
          options['size'] = readableSize(options['size']);
          showMessage(i18n['uploading'], options);
        }
      };
    })();

    AWS.config.region = 'ap-northeast-1';
    AWS.config.credentials = new AWS.CognitoIdentityCredentials({
      IdentityPoolId: this.options.IdentityPoolId,
    });

    self.metadata = {
      filename: fileAttrs.name,
      filesize: '' + fileAttrs.size,
      filetype: fileAttrs.type,
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

  notifyUploadCompleted(metadata, callback, error_callback) {
    $.post(this.notifyUrl, metadata).done(callback).fail(error_callback);
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

    if (!file.name.match(/^twitter-20\d{2}-\d{2}-\d{2}-[a-z0-9]+.zip$/i)) {
      this.errors = ['invalidFilename'];
    } else if (Date.now() - Date.parse(file.name.match(/20\d{2}-\d{2}-\d{2}/)[0]) > 7 * 24 * 60 * 60 * 1000) {
      this.errors = ['tooOldFile'];
    } else if (file.type.indexOf('zip') === -1 && file.type.indexOf('octet-stream' === -1)) {
      this.errors = ['invalidContentType'];
    } else if (file.size < 1000000) { // 1MB
      this.errors = ['filesizeTooSmall'];
    } else if (file.size > 60000000000) { // 60GB
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
}


function showMessage(message, options) {
  if (options) {
    Object.keys(options).forEach(function (key) {
      message = message.replace('{' + key + '}', escapeHtml('' + options[key]));
    });
  }
  ToastMessage.info(message, {autohide: false});
}

function readableSize(size) {
  var i = Math.floor(Math.log(size) / Math.log(1024));
  return (size / Math.pow(1024, i)).toFixed(2) * 1 + ['B', 'kB', 'MB', 'GB', 'TB'][i];
}

function truncateFilename(name) {
  return name.slice(0, 22) + '...' + name.slice(name.length - 10);
}

function escapeHtml(str) {
  if (str.length >= 30) {
    str = truncateFilename(str);
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

function readTweetFiles(file) {
  var zip = window.zip;
  var data = {};
  var processedCount = 0;
  var dirname = file.name.split('.')[0];
  var reader = new zip.ZipReader(new zip.BlobReader(file));

  return new Promise(function (resolve, reject) {
    reader.getEntries().then(function (entries) {
      if (!entries.length) {
        return reject('No entry found');
      }

      var filteredEntries = entries.filter(function (entry) {
        return !entry.directory && entry.filename.match(/^data\/tweet.*\.js$/);
      });

      if (!filteredEntries.length) {
        return reject('No filtered entry found');
      }

      filteredEntries.forEach(function (entry) {
        entry.getData(new zip.TextWriter()).then(function (text) {
          data[dirname + '/' + entry.filename] = text;
          processedCount++;

          if (processedCount === filteredEntries.length) {
            reader.close().then(function () {
              resolve(data);
            }).catch(function (err) {
              reject('reader.close() failed', err);
            });
          }
        }).catch(function (err) {
          reject('entry.getData() failed', err);
        });
      });
    }).catch(function (err) {
      reject('getEntries() failed', err);
    });
  });
}

function writeTweetFiles(data) {
  var zip = window.zip;
  var processedCount = 0;
  var writer = new zip.ZipWriter(new zip.BlobWriter('application/zip'), {bufferedWrite: true});

  var dataKeys = Object.keys(data);

  return new Promise(function (resolve, reject) {
    if (dataKeys.length === 0) {
      return reject('dataKeys is empty');
    }

    dataKeys.forEach(function (key) {
      var blob = new Blob([data[key]], {type: 'text/plain'});

      writer.add(key, new zip.BlobReader(blob)).then(function () {
        processedCount++;

        if (processedCount === dataKeys.length) {
          writer.close().then(function (result) {
            resolve(result);
          }).catch(function (err) {
            reject('writer.close() failed', err);
          });
        }
      }).catch(function (err) {
        reject('writer.add() failed', err);
      });
    });
  });
}
