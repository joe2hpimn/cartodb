var CoreView = require('backbone/core-view');
var $ = require('jquery');
var _ = require('underscore');
var ColorPicker = require('../form-components/editors/fill/color-picker/color-picker.js');
var COLOR_KEYWORDS = require('../../helpers/color-keywords');

/**
 *  Show color picker when user clicks over
 *  a color in the Codemirror editor.
 *
 *  new CodemirrorColorPicker({
 *    editor: codemirror-editor...
 *  })
 */

module.exports = CoreView.extend({

  initialize: function (opts) {
    if (!opts.editor) { throw new Error('editor is required'); }

    this._editor = opts.editor;
    this._initBinds();
  },

  _initBinds: function () {
    var self = this;
    var destroyPicker = function () {
      this._destroyPicker();
    }.bind(this);

    this._editor.on('mousedown', function (cm, ev) {
      _.delay(self._onClick.bind(self), 50);
    }, this);
    this._editor.on('blur', destroyPicker, this);
    this._editor.on('viewportChange', destroyPicker, this);
    this._editor.on('scroll', destroyPicker, this);
  },

  _disableBinds: function () {
    this._editor.off(null, null, this);
  },

  _onClick: function (ev) {
    var cursor = this._editor.getCursor(true);
    var token = this._editor.getTokenAt(cursor);

    if (token.type === 'color') {
      this._createPicker(ev, cursor, token);
    } else {
      this._destroyPicker();
    }
  },

  _replaceColor: function (color) {
    var cursor = this._editor.getCursor();

    var nameMatch = this._getMatch(cursor, 'name');
    var hexMatch = this._getMatch(cursor, 'hex');
    var match = nameMatch || hexMatch;

    var start = {
      line: cursor.line,
      ch: match.start
    };
    var end = {
      line: cursor.line,
      ch: match.end
    };

    this._editor.replaceRange(color, start, end);
  },

  _getMatch: function (cursor, type) {
    if (!type) return;
    var re;

    switch (type.toLowerCase()) {
      case 'name':
        re = new RegExp(COLOR_KEYWORDS.join('|'), 'g');
        break;
      case 'hsl':
        re = /hsla?\(\s*(\d{1,3})\s*,\s*(\d{1,3}\%)\s*,\s*(\d{1,3}\%)\s*(?:\s*,\s*(\d+(?:\.\d+)?)\s*)?\)/g;
        break;
      case 'rgb':
        re = /rgb\((\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3})\)/;
        break;
      case 'hex':
        re = /#[a-fA-F0-9]{3,6}/g;
        break;
      default:
        console.log('Invalid color match selection');
        return;
    }

    var line = this._editor.getLine(cursor.line);
    var match = re.exec(line);

    while (match) {
      var val = match[0];
      var len = val.length;
      var start = match.index;
      var end = match.index + len;
      if (cursor.ch >= start && cursor.ch <= end) {
        match = null;
        return {
          start: start,
          end: end,
          string: val
        };
      }
      match = re.exec(line);
    }
    return;
  },

  _createPicker: function (cursor, token) {
    var cursorCoords = this._editor.cursorCoords();
    this._destroyPicker();

    this._colorPicker = new ColorPicker({
      className: 'Editor-boxModal Editor-FormDialog CDB-Text',
      value: token.string,
      disableOpacity: true
    });

    this._colorPicker.bind('change', function (values) {
      this._replaceColor(values.hex);
      this.trigger('codeSaved');
    }, this);

    this._colorPicker.$el.css({
      left: cursorCoords.left,
      top: cursorCoords.top + 20
    });

    $('body').append(this._colorPicker.render().el);
  },

  _destroyPicker: function () {
    if (this._colorPicker) {
      this.removeView(this._colorPicker);
      this._colorPicker.clean();
      delete this._colorPicker;
    }
  },

  clean: function () {
    this._disableBinds();
    CoreView.prototype.clean.call(this);
  }
});