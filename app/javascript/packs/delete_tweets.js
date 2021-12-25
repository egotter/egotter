class DeleteTweetsDatesSelector {
  constructor(since_id, until_id) {
    this.$since = $('#' + since_id);
    this.$until = $('#' + until_id);
    this.$since_label = $('label[for="' + since_id + '"]');
    this.$until_label = $('label[for="' + until_id + '"]');

    this.$since.on('change', this.validate.bind(this));
    this.$until.on('change', this.validate.bind(this));
  }

  validate() {
    var v1 = this.$since.val();
    var v2 = this.$until.val();

    if (!v1 || !v2) {
      this.$since_label.removeClass('text-danger');
      this.$until_label.removeClass('text-danger');
      return true;
    }

    var d1 = Date.parse(v1);
    var d2 = Date.parse(v2);

    if (d1 <= d2) {
      this.$since_label.removeClass('text-danger');
      this.$until_label.removeClass('text-danger');
      return true;
    } else {
      this.$since_label.addClass('text-danger');
      this.$until_label.addClass('text-danger');
      return false;
    }
  }
}

window.DeleteTweetsDatesSelector = DeleteTweetsDatesSelector;

class DeleteTweetsRequiredCheckbox {
  constructor(id) {
    this.id = id;
    this.$elem = $('#' + id);
    this.$elem.on('change', this.validate.bind(this));
  }

  validate() {
    var $label = $('label[for="' + this.id + '"]');

    if (this.$elem.prop('checked')) {
      $label.removeClass('text-danger');
      return true;
    } else {
      $label.addClass('text-danger');
      return false;
    }
  }
}

window.DeleteTweetsRequiredCheckbox = DeleteTweetsRequiredCheckbox;
