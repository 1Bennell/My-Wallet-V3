var Exchange = require('bitcoin-exchange-client');
var PaymentMethod = require('./payment-medium');
var Trade = require('./trade');

// I use Coinify's convention for the meaning of base & quote currency.
class Quote extends Exchange.Quote {
  constructor (obj, amountCurrency, api, delegate, debug) {
    super(api, delegate, Trade, PaymentMethod, debug);

    var expiresAt = new Date(obj.expires_on);

    this._id = obj.quote_id;
    this._baseCurrency = amountCurrency.toUpperCase();
    if (this._baseCurrency === 'USD') {
      this._quoteCurrency = 'BTC';
      this._baseAmount = Math.round(obj.quote_amount * 100);
      this._quoteAmount = Math.round(obj.base_amount * 100000000);
    } else {
      this._quoteCurrency = 'USD';
      this._baseAmount = Math.round(obj.base_amount * 100000000);
      this._quoteAmount = Math.round(obj.quote_amount * 100);
    }
    this._rate = (obj.quote_amount / obj.base_amount).toFixed(2);
    this._expiresAt = expiresAt;
  }

  get rate () {
    return this._rate;
  }

  static getQuote (api, delegate, amount, baseCurrency, quoteCurrency, debug) {
    const processQuote = (quote) => {
      let q = new Quote(quote, baseCurrency, api, delegate);
      q.debug = debug;
      return q;
    };

    const getQuote = (_baseAmount) => {
      var getQuote = function () {
        return api.POST('quote/', {
          action: 'buy',
          base_currency: 'btc',
          quote_currency: 'usd',
          amount: _baseAmount,
          amount_currency: baseCurrency.toLowerCase()
        }, 'v1', 'quotes');
      };

      return getQuote().then(processQuote);
    };

    return super.getQuote(-amount, baseCurrency, quoteCurrency, ['BTC', 'EUR', 'GBP', 'USD', 'DKK'], debug)
             .then(getQuote);
  }
}

module.exports = Quote;
