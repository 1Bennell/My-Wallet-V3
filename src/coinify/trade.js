'use strict';

var assert = require('assert');

var BankAccount = require('./bank-account');
var Helpers = require('./helpers');
var Quote = require('./quote');

module.exports = CoinifyTrade;

function CoinifyTrade (obj, api, coinifyDelegate) {
  assert(obj, 'JSON missing');
  assert(api, 'Coinify API missing');
  assert(coinifyDelegate, 'coinifyDelegate missing');
  assert(typeof coinifyDelegate.getReceiveAddress === 'function', 'delegate requires getReceiveAddress()');
  this._coinifyDelegate = coinifyDelegate;
  this._api = api;
  this._id = obj.id;
  this.set(obj);
}

Object.defineProperties(CoinifyTrade.prototype, {
  'debug': {
    configurable: false,
    get: function () { return this._debug; },
    set: function (value) {
      this._debug = Boolean(value);
    }
  },
  'id': {
    configurable: false,
    get: function () {
      return this._id;
    }
  },
  'iSignThisID': {
    configurable: false,
    get: function () {
      return this._iSignThisID;
    }
  },
  'quoteExpireTime': {
    configurable: false,
    get: function () {
      return this._quoteExpireTime;
    }
  },
  'bankAccount': {
    configurable: false,
    get: function () {
      return this._bankAccount;
    }
  },
  'createdAt': {
    configurable: false,
    get: function () {
      return this._createdAt;
    }
  },
  'updatedAt': {
    configurable: false,
    get: function () {
      return this._updatedAt;
    }
  },
  'inCurrency': {
    configurable: false,
    get: function () {
      return this._inCurrency;
    }
  },
  'outCurrency': {
    configurable: false,
    get: function () {
      return this._outCurrency;
    }
  },
  'inAmount': {
    configurable: false,
    get: function () {
      return this._inAmount;
    }
  },
  'medium': {
    configurable: false,
    get: function () {
      return this._medium;
    }
  },
  'state': {
    configurable: false,
    get: function () {
      return this._state;
    }
  },
  'sendAmount': {
    configurable: false,
    get: function () {
      return this._sendAmount;
    }
  },
  'outAmount': {
    configurable: false,
    get: function () {
      return this._outAmount;
    }
  },
  'outAmountExpected': {
    configurable: false,
    get: function () {
      return this._outAmountExpected;
    }
  },
  'receiptUrl': {
    configurable: false,
    get: function () {
      return this._receiptUrl;
    }
  },
  'receiveAddress': {
    configurable: false,
    get: function () {
      return this._receiveAddress;
    }
  },
  'accountIndex': {
    configurable: false,
    get: function () {
      return this._account_index;
    }
  },
  'bitcoinReceived': {
    configurable: false,
    get: function () {
      return Boolean(this._txHash);
    }
  },
  'confirmed': {
    configurable: false,
    get: function () {
      return this._confirmed || this._confirmations >= 3;
    }
  },
  'isBuy': {
    configurable: false,
    get: function () {
      if (Boolean(this._is_buy) === this._is_buy) {
        return this._is_buy;
      } else if (this._is_buy === undefined && this.outCurrency === undefined) {
        return true; // For older test wallets, can be safely removed later.
      } else {
        return this.outCurrency === 'BTC';
      }
    }
  },
  'txHash': {
    configurable: false,
    get: function () { return this._txHash || null; }
  }
});

CoinifyTrade.prototype.set = function (obj) {
  if ([
    'awaiting_transfer_in',
    'processing',
    'reviewing',
    'completed',
    'completed_test',
    'cancelled',
    'rejected',
    'expired'
  ].indexOf(obj.state) === -1) {
    console.warn('Unknown state:', obj.state);
  }
  if (this._isDeclined && obj.state === 'awaiting_transfer_in') {
    // Coinify API may lag a bit behind the iSignThis iframe.
    this._state = 'rejected';
  } else {
    this._state = obj.state;
  }
  this._is_buy = obj.is_buy;

  this._inCurrency = obj.inCurrency;
  this._outCurrency = obj.outCurrency;

  if (obj.transferIn) {
    this._medium = obj.transferIn.medium;
    this._sendAmount = this._inCurrency === 'BTC'
      ? Helpers.toSatoshi(obj.transferIn.sendAmount)
      : Helpers.toCents(obj.transferIn.sendAmount);
  }

  if (this._inCurrency === 'BTC') {
    this._inAmount = Helpers.toSatoshi(obj.inAmount);
    this._outAmount = Helpers.toCents(obj.outAmount);
    this._outAmountExpected = Helpers.toCents(obj.outAmountExpected);
  } else {
    this._inAmount = Helpers.toCents(obj.inAmount);
    this._outAmount = Helpers.toSatoshi(obj.outAmount);
    this._outAmountExpected = Helpers.toSatoshi(obj.outAmountExpected);
  }

  if (obj.confirmed === Boolean(obj.confirmed)) {
    this._coinifyDelegate.deserializeExtraFields(obj, this);
    this._receiveAddress = this._coinifyDelegate.getReceiveAddress(this);
    this._confirmed = obj.confirmed;
    this._txHash = obj.tx_hash;
  } else { // Contructed from Coinify API
    /* istanbul ignore if */
    if (this.debug) {
      // This log only happens if .set() is called after .debug is set.
      console.info('Trade ' + this.id + ' from Coinify API');
    }
    this._createdAt = new Date(obj.createTime);
    this._updatedAt = new Date(obj.updateTime);
    this._quoteExpireTime = new Date(obj.quoteExpireTime);
    this._receiptUrl = obj.receiptUrl;

    if (this._inCurrency !== 'BTC') {
      // NOTE: this field is currently missing in the Coinify API:
      if (obj.transferOut && obj.transferOutdetails && obj.transferOutdetails.transaction) {
        this._txHash = obj.transferOutdetails.transaction;
      }

      if (this._medium === 'bank') {
        this._bankAccount = new BankAccount(obj.transferIn.details);
      }

      this._receiveAddress = obj.transferOut.details.account;
      this._iSignThisID = obj.transferIn.details.paymentId;
    }
  }

  return this;
};

CoinifyTrade.prototype.cancel = function () {
  var self = this;

  var processCancel = function (trade) {
    self._state = trade.state;

    self._coinifyDelegate.releaseReceiveAddress(self);

    return self._coinifyDelegate.save.bind(self._coinifyDelegate)();
  };

  return self._api.authPATCH('trades/' + self._id + '/cancel').then(processCancel);
};

// Checks the balance for the receive address and monitors the websocket if needed:
// Call this method long before the user completes the purchase:
// trade.watchAddress.then(() => ...);
CoinifyTrade.prototype.watchAddress = function () {
  /* istanbul ignore if */
  if (this.debug) {
    console.info('Watch ' + this.receiveAddress + ' for ' + this.state + ' trade ' + this.id);
  }
  var self = this;
  var promise = new Promise(function (resolve, reject) {
    self._watchAddressResolve = resolve;
  });
  return promise;
};

CoinifyTrade.prototype.btcExpected = function () {
  var self = this;
  if (this.isBuy) {
    if ([
      'completed',
      'completed_test',
      'cancelled',
      'rejected'
    ].indexOf(this.state) > -1) {
      return Promise.resolve(this.outAmountExpected);
    }

    var oneMinuteAgo = new Date(new Date().getTime() - 60 * 1000);
    if (this.quoteExpireTime > new Date()) {
      // Quoted price still valid
      return Promise.resolve(this.outAmountExpected);
    } else {
      // Estimate BTC expected based on current exchange rate:
      if (this._lastBtcExpectedGuessAt > oneMinuteAgo) {
        return Promise.resolve(this._lastBtcExpectedGuess);
      } else {
        var processQuote = function (quote) {
          self._lastBtcExpectedGuess = quote.quoteAmount;
          self._lastBtcExpectedGuessAt = new Date();
          return self._lastBtcExpectedGuess;
        };
        return Quote.getQuote(this._api, -this.inAmount, this.inCurrency).then(processQuote);
      }
    }
  } else {
    return Promise.reject();
  }
};

// QA tool:
CoinifyTrade.prototype.fakeBankTransfer = function () {
  var self = this;

  return self._api.authPOST('trades/' + self._id + '/test/bank-transfer', {
    sendAmount: parseFloat((self.inAmount / 100).toFixed(2)),
    currency: self.inCurrency
  });
};

// QA tool:
CoinifyTrade.prototype.expireQuote = function () {
  this._quoteExpireTime = new Date(new Date().getTime() + 3000);
};

CoinifyTrade.buy = function (quote, medium, api, coinifyDelegate, debug) {
  assert(quote, 'Quote required');

  /* istanbul ignore if */
  if (debug) {
    console.info('Reserve receive address for new trade');
  }
  var reservation = coinifyDelegate.reserveReceiveAddress();

  var processTrade = function (res) {
    var trade = new CoinifyTrade(res, api, coinifyDelegate);
    trade.debug = debug;

    /* istanbul ignore if */
    if (debug) {
      console.info('Commit receive address for new trade');
    }
    reservation.commit(trade);

    /* istanbul ignore if */
    if (debug) {
      console.info('Monitor trade', trade.receiveAddress);
    }
    trade._monitorAddress.bind(trade)();
    return trade;
  };

  var error = function (e) {
    console.error(e);
    return Promise.reject(e);
  };

  return api.authPOST('trades', {
    priceQuoteId: quote.id,
    transferIn: {
      medium: medium
    },
    transferOut: {
      medium: 'blockchain',
      details: {
        account: reservation.receiveAddress
      }
    }
  }).then(processTrade).catch(error);
};

CoinifyTrade.fetchAll = function (api) {
  return api.authGET('trades');
};

CoinifyTrade.prototype.self = function () {
  return this;
};

CoinifyTrade.prototype.process = function () {
  if (['rejected', 'cancelled', 'expired'].indexOf(this.state) > -1) {
    /* istanbul ignore if */
    if (this.debug) {
      console.info('Check if address for ' + this.state + ' trade ' + this.id + ' can be released');
    }
    this._coinifyDelegate.releaseReceiveAddress(this);
  }
};

CoinifyTrade.prototype.refresh = function () {
  /* istanbul ignore if */
  if (this.debug) {
    console.info('Refresh ' + this.state + ' trade ' + this.id);
  }
  return this._api.authGET('trades/' + this._id)
          .then(this.set.bind(this))
          .then(this._coinifyDelegate.save.bind(this._coinifyDelegate))
          .then(this.self.bind(this));
};

// Call this if the iSignThis iframe says the card is declined. It may take a
// while before Coinify API reflects this change
CoinifyTrade.prototype.declined = function () {
  this._state = 'rejected';
  this._isDeclined = true;
};

CoinifyTrade.prototype._monitorAddress = function () {
  var self = this;

  var tradeWasPaid = function (amount) {
    /* istanbul ignore if */
    if (self.debug) {
      console.info(amount + ' paid for trade ' + self.id);
    }
    var resolve = function () {
      self._watchAddressResolve && self._watchAddressResolve(amount);
    };
    self._coinifyDelegate.save().then(resolve);
  };

  self._coinifyDelegate.monitorAddress(self.receiveAddress, function (hash, amount) {
    var updateTrade = function () {
      /* istanbul ignore if */
      if (self.debug) {
        console.info('Transaction ' + hash + ' detected, considering ' + self.state + ' trade ' + self.id);
      }
      if (self.state === 'completed_test' && !self.confirmations && !self._txHash) {
        // For test trades, there is no real transaction, so trade._txHash is not
        // set. Instead use the hash for the incoming transaction. This will not
        // work correctly with address reuse.
        /* istanbul ignore if */
        if (self.debug) {
          console.info('Test trade, not matched before, unconfirmed transaction, assuming match');
        }
        self._txHash = hash;
        tradeWasPaid(amount);
      } else if (self.state === 'completed' || self.state === 'processing') {
        if (self._txHash) {
          // Multiple trades may reuse the same address if e.g. one is
          // cancelled of if we reach the gap limit.
          /* istanbul ignore if */
          if (self.debug) {
            console.info('Trade already matched, ignoring transaction');
          }
          if (self._txHash !== hash) return;
        } else {
          // transferOut.details.transaction is not implemented and might be
          // missing if in the processing state.
          /* istanbul ignore if */
          if (self.debug) {
            console.info('Trade not matched yet, assuming match');
          }
          self._txHash = hash;
        }
        tradeWasPaid(amount);
      } else {
        /* istanbul ignore if */
        if (self.debug) {
          console.info('Not calling tradeWasPaid()');
        }
      }
    };

    if (self.state === 'completed' || self.state === 'processing' || self.state === 'completed_test') {
      updateTrade();
    } else {
      self.refresh().then(updateTrade);
    }
  });
};

CoinifyTrade._checkOnce = function (trades, coinifyDelegate) {
  assert(coinifyDelegate, '_checkOnce needs delegate');

  var getReceiveAddress = function (obj) { return obj.receiveAddress; };

  var receiveAddresses = trades.map(getReceiveAddress);

  if (receiveAddresses.length === 0) {
    return Promise.resolve();
  }

  var promises = [];

  for (var i = 0; i < trades.length; i++) {
    promises.push(CoinifyTrade._setTransactionHash(trades[i], coinifyDelegate));
  }

  return Promise.all(promises).then(coinifyDelegate.save.bind(coinifyDelegate));
};

//
CoinifyTrade._setTransactionHash = function (trade, coinifyDelegate) {
  assert(coinifyDelegate, '_setTransactionHash needs delegate');
  return coinifyDelegate.checkAddress(trade.receiveAddress)
    .then(function (tx) {
      if (tx) {
        if (trade.state === 'completed_test' && !trade._txHash) {
          // See remarks below
          trade._txHash = tx.hash;
        } else if (trade.state === 'processing' || trade.state === 'completed') {
          if (trade._txHash) {
            if (trade._txHash !== tx.hash) return;
          } else {
            trade._txHash = tx.hash;
          }
        } else {
          return;
        }
        trade._confirmations = tx.confirmations;
        // TODO: refactor
        if (trade.confirmed) {
          trade._confirmed = true;
        }
      }
    });
};

CoinifyTrade._monitorWebSockets = function (trades) {
  for (var i = 0; i < trades.length; i++) {
    var trade = trades[i];
    trade._monitorAddress.bind(trade)();
  }
};

// Monitor the receive addresses for pending and completed trades.
CoinifyTrade.monitorPayments = function (trades, coinifyDelegate) {
  assert(coinifyDelegate, '_monitorPayments needs delegate');

  var tradeFilter = function (trade) {
    return [
      'awaiting_transfer_in',
      'reviewing',
      'processing',
      'completed',
      'completed_test'
    ].indexOf(trade.state) > -1 && !trade.confirmed;
  };

  var filteredTrades = trades.filter(tradeFilter);

  CoinifyTrade._checkOnce(filteredTrades, coinifyDelegate).then(function () {
    CoinifyTrade._monitorWebSockets(filteredTrades);
  });
};

CoinifyTrade.prototype.toJSON = function () {
  var serialized = {
    id: this._id,
    state: this._state,
    tx_hash: this._txHash,
    confirmed: this.confirmed,
    is_buy: this.isBuy
  };

  this._coinifyDelegate.serializeExtraFields(serialized, this);

  return serialized;
};

CoinifyTrade.filteredTrades = function (trades) {
  return trades.filter(function (trade) {
    // Only consider transactions that are complete or that we're still
    // expecting payment for:
    return [
      'awaiting_transfer_in',
      'processing',
      'reviewing',
      'completed',
      'completed_test'
    ].indexOf(trade.state) > -1;
  });
};
