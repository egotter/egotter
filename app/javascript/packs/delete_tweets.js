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
