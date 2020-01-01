'use strict';

var Welcome = {};

Welcome.ShareDialog = function () {
    if (this === undefined) {
        throw new TypeError();
    }

    this._modal = $('#share-modal');
    this._cache = window['sessionStorage'] || {};

    var modal = this._modal;

    modal.find('button.ok').on('click', function () {
        var $clicked = $(this);
        var tweet = modal.find('textarea').val();

        $.post($clicked.data('url'), {text: tweet}).done(function (res) {
            var text = $clicked.data('success-message');
            $('#global-info-message-box').find('.message').text(text).end().show();

            // if (window.location.pathname.startsWith('/settings')) {
            //   window.location.reload();
            // }
        }).fail(function (xhr) {
            var reason = $clicked.data('error-message');
            if (xhr.status === 400 && xhr.responseText && JSON.parse(xhr.responseText)['reason']) {
                reason = JSON.parse(xhr.responseText)['reason'];
            }
            $('#global-warning-message-box').find('.message').text(reason).end().show();
        });

        modal.modal('hide');
    });
};

Welcome.ShareDialog.prototype = {
    constructor: Welcome.ShareDialog,
    show: function (force) {
        if (force) {
            this._modal.modal();
        } else {
            if (!this._cache['share_dialog']) {
                this._cache['share_dialog'] = true;
                this._modal.modal();
            }
        }
    }
};

Welcome.FollowDialog = function () {
    if (this === undefined) {
        throw new TypeError();
    }

    this._modal = $('#follow-modal');
    this._cache = window['sessionStorage'] || {};

    var modal = this._modal;

    modal.find('button.ok').on('click', function () {
        var $clicked = $(this);
        window.open($clicked.data('follow-url'), '_blank');

        $.post($clicked.data('url'), {uid: $clicked.data('uid')}, function (res) {
            console.log('createFollow', res);
        });

        modal.modal('hide');
    });
};

Welcome.FollowDialog.prototype = {
    constructor: Welcome.FollowDialog,
    show: function () {
        if (!this._cache['follow_dialog']) {
            this._cache['follow_dialog'] = true;
            this._modal.modal();
        }
    },
    on: function (event, fn) {
        this._modal.on(event, fn);
    }
};

$(function () {
    function getParameterByName(name, url) {
        if (!url) url = window.location.href;
        name = name.replace(/[\[\]]/g, '\\$&');
        var regex = new RegExp('[?&]' + name + '(=([^&#]*)|&|#|$)'),
            results = regex.exec(url);
        if (!results) return null;
        if (!results[2]) return '';
        return decodeURIComponent(results[2].replace(/\+/g, ' '));
    }

    var shareDialog = new Welcome.ShareDialog();
    var followDialog = new Welcome.FollowDialog();

    if (getParameterByName('follow_dialog') === '1' && getParameterByName('share_dialog') === '1') {
        followDialog.on('hidden.bs.modal', function (e) {
            shareDialog.show();
        });
        followDialog.show();
    } else if (getParameterByName('follow_dialog') === '1') {
        followDialog.show();
    } else if (getParameterByName('share_dialog') === '1') {
        shareDialog.show();
    }
});