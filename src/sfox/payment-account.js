var ExchangePaymentAccount = require('../exchange/payment-account');
var Trade = require('./trade');
var assert = require('assert');

class PaymentAccount extends ExchangePaymentAccount {
  constructor (obj, api, quote) {
    super(api, 'ach', quote, Trade);

    this._TradeClass = Trade;

    this._id = obj.payment_method_id;
    this._status = obj.status;
    this._routingNumber = obj.routing_number;
    this._accountNumber = obj.account_number;
    this._name = obj.name;
    this._accountType = obj.account_type;
  }

  get status () { return this._status; }

  get routingNumber () { return this._routingNumber; }

  get accountNumber () { return this._accountNumber; }

  get accountType () { return this._accountType; }

  buy () {
    if (this.status !== 'active') {
      return Promise.reject('ACH_ACCOUNT_INACTIVE');
    }
    return super.buy();
  }

  verify (amount1, amount2) {
    assert(amount1 && amount2, 'Split amounts required');
    return this._api.authPOST('payment-methods/verify', {
      payment_method_id: this._id,
      amount1: amount1,
      amount2: amount2
    }).then((res) => {
      this._status = res.status;
      return this;
    });
  }

  static getAll () {
    return this._api.authGET('payment-methods').then((accounts) => {
      let accountsObj = [];
      for (let account of accounts) {
        accountsObj.push(new PaymentAccount(account, this._api));
      }
      return accountsObj;
    });
  }

  static add (api, routingNumber, accountNumber, name, nickname, type) {
    assert(routingNumber && accountNumber, 'Routing and account number required');
    assert(name, 'Account holder name required');
    assert(nickname, 'Nickname required');

    return api.authPOST('payment-methods', {
      type: 'ach',
      ach: {
        currency: 'usd',
        routing_number: routingNumber,
        account_number: accountNumber,
        name1: name,
        nickname: nickname,
        type: type || 'checking'
      }
    }).then((res) => {
      return new PaymentAccount(res, api);
    });
  }
}

module.exports = PaymentAccount;
