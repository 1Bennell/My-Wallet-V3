/* eslint-disable semi */
require('isomorphic-fetch')
let API = require('../src/api');

describe('API', () => {
  describe('encodeFormData', () => {
    it('should encode a flat list', () => {
      let data = { foo: 'bar', alice: 'bob' };
      expect(API.encodeFormData(data)).toEqual('foo=bar&alice=bob');
    });

    it('should encode a nested list', () => {
      pending();
      let data = {
        foo: 'bar',
        name: { first: 'bob' }
      };
      expect(API.encodeFormData(data)).toEqual('...');
    });
  });

  describe('.incrementBtcEthUsageStats', () => {
    let eventUrl = (event) => `https://blockchain.info/event?name=wallet_login_balance_${event}`

    beforeEach(() => {
      spyOn(window, 'fetch')
    })

    it('should make three requests, one for each stat', () => {
      API.incrementBtcEthUsageStats(0, 0)
      expect(window.fetch).toHaveBeenCalledTimes(3)
    })

    it('should record correctly for btc=0, eth=0', () => {
      API.incrementBtcEthUsageStats(0, 0)
      expect(window.fetch).toHaveBeenCalledWith(eventUrl('btc_0'))
      expect(window.fetch).toHaveBeenCalledWith(eventUrl('eth_0'))
      expect(window.fetch).toHaveBeenCalledWith(eventUrl('btceth_0'))
    })

    it('should record correctly for btc>0, eth=0', () => {
      API.incrementBtcEthUsageStats(1, 0)
      expect(window.fetch).toHaveBeenCalledWith(eventUrl('btc_1'))
      expect(window.fetch).toHaveBeenCalledWith(eventUrl('eth_0'))
      expect(window.fetch).toHaveBeenCalledWith(eventUrl('btceth_0'))
    })

    it('should record correctly for btc=0, eth>0', () => {
      API.incrementBtcEthUsageStats(0, 1)
      expect(window.fetch).toHaveBeenCalledWith(eventUrl('btc_0'))
      expect(window.fetch).toHaveBeenCalledWith(eventUrl('eth_1'))
      expect(window.fetch).toHaveBeenCalledWith(eventUrl('btceth_0'))
    })

    it('should record correctly for btc>0, eth>0', () => {
      API.incrementBtcEthUsageStats(1, 1)
      expect(window.fetch).toHaveBeenCalledWith(eventUrl('btc_1'))
      expect(window.fetch).toHaveBeenCalledWith(eventUrl('eth_1'))
      expect(window.fetch).toHaveBeenCalledWith(eventUrl('btceth_1'))
    })
  })
});
