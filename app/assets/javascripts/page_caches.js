$(function () {
  window.delete_cache = function (url, hash) {
    return $.ajax({url: url.replace(/HASH/, hash), type: 'DELETE'})
        .done(function (res) {
          console.log(res);
        })
        .fail(function (xhr) {
          console.log(xhr.responseText);
        });
  };

  window.create_cache = function (url) {
    return $.post(url)
        .done(function (res) {
          console.log(res);
        })
        .fail(function (xhr) {
          console.log(xhr.responseText);
        });
  };
});