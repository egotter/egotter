class MessageBox {
  constructor(requestToUpdate, nextCreationTimeMessage) {
    this._boxes = {
      update: $('#update-box'),
      updateThisPage: $('#update-this-page-box'),
      requestToUpdate: $('#request-to-update-box'),
      failed: $('#failed-box'),
      refresh: $('#refresh-box'),
      tooManyFriends: $('#too-many-friends-box'),
      follow: $('#follow-box'),
      justFollowed: $('#just-followed-box'),
      notFollowed: $('#not-followed-box'),
      invalidToken: $('#invalid-token-box'),
      accurateCounting: $('#accurate-counting-box'),
      viaDM: $('#via-dm-box'),
      signIn: $('#sign-in-box'),
      tooManySearches: $('#too-many-searches-box')
    };

    if (requestToUpdate) {
      console.log('Switch to request', requestToUpdate);
      this._boxes['updateThisPage'] = this._boxes['requestToUpdate'];
    }

    console.log('message', nextCreationTimeMessage);
    this._boxes['updateThisPage'].find('.next-creation-note').html(nextCreationTimeMessage);
  }

  find(name) {
    return this._boxes[name];
  }

  show(name) {
    this.showToast(name);
  }

  showToast(name, message) {
    var $box = this._boxes[name];
    console.log('showToast', name, $box, message);

    if (!message) {
      message = $box.find('.inner').html();
    }

    ToastMessage.show(message);
  }

}

window.MessageBox = MessageBox;
