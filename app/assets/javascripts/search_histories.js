function loadSearchHistories (selector, loadPath, inModal) {
  $.get(loadPath, {in_modal: inModal})
      .done(function (res) {
        $(selector).append(res.html);
      })
      .fail(function (xhr) {
        console.log(xhr.responseText);
      });
}
