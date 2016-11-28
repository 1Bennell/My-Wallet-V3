var ExchangeQuote = require('../exchange/quote');
var Trade = require('./trade');

// I use Coinify's convention for the meaning of base & quote currency.
class Quote extends ExchangeQuote {
  constructor (obj, amountCurrency, api, delegate, debug) {
    super(api, delegate, Trade, debug);

    var expiresAt = new Date(obj.expires_on);

    this._id = obj.quote_id;
    this._baseCurrency = amountCurrency.toUpperCase();
    if (this._baseCurrency === 'USD') {
      this._quoteCurrency = 'BTC';
      this._baseAmount = Math.round(obj.quote_amount * 100);
      this._quoteAmount = Math.round(obj.base_amount * 100000000);
    } else {
      this._quoteCurrency = 'USD';
      this._baseAmount = Math.round(obj.quote_amount * 100000000);
      this._quoteAmount = Math.round(obj.base_amount * 100);
    }
    this._expiresAt = expiresAt;
  }

  static getQuote (api, delegate, amount, baseCurrency, quoteCurrency, debug) {
    const processQuote = (quote) => new Quote(quote, baseCurrency, api, delegate);

    const getQuote = (_baseAmount) => {
      var getQuote = function () {
        return api.POST('quote', {
          action: 'buy',
          base_currency: 'btc',
          quote_currency: 'usd',
          amount: parseFloat(_baseAmount),
          amount_currency: baseCurrency
        }, 'v1', 'quotes');
      };

      return getQuote().then(processQuote);
    };

    return super.getQuote(amount, baseCurrency, quoteCurrency, ['BTC', 'EUR', 'GBP', 'USD', 'DKK'], debug)
             .then(getQuote);
  }

  buy () {
    return super.buy('bank');
  }
}

module.exports = Quote;
