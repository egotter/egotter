window.Egotter = {};

function extractErrorMessage(xhr, textStatus, errorThrown) {
  var message;
  try {
    message = JSON.parse(xhr.responseText)['message'];
  } catch (e) {
    logger.error(e);
  }
  if (!message) {
    message = xhr.status + ' (' + errorThrown + ')';
  }
  return message;
}

window.extractErrorMessage = extractErrorMessage;

function showErrorMessage(xhr, textStatus, errorThrown) {
  var message = extractErrorMessage(xhr, textStatus, errorThrown);
  ToastMessage.warn(message);
  return message;
}

window.showErrorMessage = showErrorMessage;
