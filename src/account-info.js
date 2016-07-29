'use strict';

var assert = require('assert');
var Helpers = require('./helpers');

module.exports = AccountInfo;

function AccountInfo (object) {
  this._email = object.email;

  if (object.sms_number && object.sms_number.length > 5) {
    this._mobile = {
      countryCode: object.sms_number.split(' ')[0].substr(1),
      number: object.sms_number.split(' ')[1]
    };
  } else {
    this._mobile = null;
  }

  this._countryCodeGuess = object.country_code; // Country guess by the backend
  this._dialCode = object.dial_code; // Dialcode guess by the backend

  this._isEmailVerified = Boolean(object.email_verified);
  this._isMobileVerified = Boolean(object.sms_verified);

  this._currency = object.currency;

  this._invited = object.invited;
}

Object.defineProperties(AccountInfo.prototype, {

  'email': {
    configurable: false,
    get: function () { return this._email; },
    set: function (value) {
      this._email = value;
    }
  },
  'mobileObject': {
    configurable: false,
    get: function () { return this._mobile; }
  },
  'mobile': {
    configurable: false,
    get: function () {
      return this._mobile == null
        ? null
        : '+' + this._mobile.countryCode + this._mobile.number.replace(/^0*/, '');
    }
  },
  'countryCodeGuess': {
    configurable: false,
    get: function () { return this._countryCodeGuess; }
  },
  'dialCode': {
    configurable: false,
    get: function () { return this._dialCode; }
  },
  'isEmailVerified': {
    configurable: false,
    get: function () { return this._isEmailVerified; },
    set: function (value) {
      assert(Helpers.isBoolean(value), 'Boolean');
      this._isEmailVerified = value;
    }
  },
  'isMobileVerified': {
    configurable: false,
    get: function () { return this._isMobileVerified; }
  },
  'currency': {
    configurable: false,
    get: function () { return this._currency; }
  },
  'invited': {
    configurable: false,
    get: function () { return this._invited; }
  }
});
