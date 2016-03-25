
proxyquire = require('proxyquireify')(require)
unspent = require('./data/unspent-outputs')

MyWallet =
  wallet:
    fee_per_kb: 10000
    isUpgradedToHD: true
    key: () -> { priv: null, address: '16SPAGz8vLpP3jNTcP7T2io1YccMbjhkee' }
    spendableActiveAddresses: [
      '16SPAGz8vLpP3jNTcP7T2io1YccMbjhkee',
      '1FBHaa3JNjTbhvzMBdv2ymaahmgSSJ4Mis',
      '12C5rBJ7Ev3YGBCbJPY6C8nkGhkUTNqfW9'
    ]
    hdwallet:
      accounts: [
        {
          receiveAddress: '1CAAZHV1YJcWojefgTEJMG1TjqyEzDuvA6',
          extendedPublicKey: 'xpub6DX2ZjB6qgNH5GFusizVD2yHsm7T9vD6eQNHzth4Zy6MPQim96UPdHurhXDSaz8aUtPo3XktydjkMt1ZJCL9pjPm9YXJYW3K9cYDcJAuT2v'
        },
        {
          receiveAddress: '1K8ChnK2TCpADx6auTDjB613zrf4wBsawx',
          extendedPublicKey: 'xpub6DX2ZjB6qgNH8YVEAX4tKdTGrEyLF5h2FVarCmWvRUpVREYL6c93xvt7ZFGK9x6vNjwiRxAd1pEo2WU5YNKPhnAZ8sh4CUefbGQJ8aUJaEv'
        }
      ]

API =
  getUnspent: (addresses, conf) -> Promise.resolve(unspent)

Helpers =
   guessFee: (nInputs, nOutputs, feePerKb) -> nInputs * 100

Payment = proxyquire('../src/payment', {
  './wallet': MyWallet
  './api': API,
  './helpers': Helpers
})

describe 'Payment', ->
  pending()
  payment = undefined
  hdwallet = MyWallet.wallet.hdwallet

  data =
    address: '16SPAGz8vLpP3jNTcP7T2io1YccMbjhkee'
    addressesFromPk: ['1Q57STy6daELZqToY4Rs2BKWxau2kzwjdy', '12C5rBJ7Ev3YGBCbJPY6C8nkGhkUTNqfW9'] # Compressed and uncompressed
    addresses: ['16SPAGz8vLpP3jNTcP7T2io1YccMbjhkee', '1FBHaa3JNjTbhvzMBdv2ymaahmgSSJ4Mis', '12C5rBJ7Ev3YGBCbJPY6C8nkGhkUTNqfW9']

  beforeEach ->
    JasminePromiseMatchers.install()
    payment = new Payment()

  afterEach ->
    JasminePromiseMatchers.uninstall()

  describe 'new', ->

    it 'should create a new payment', (done) ->
      spyOn(Payment, 'return').and.callThrough()
      payment = new Payment()
      expect(Payment.return).toHaveBeenCalled()
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({}), done)

    it 'should create a new payment with preset options', (done) ->
      payment = new Payment({ to: [data.address], feePerKb: 22000 })
      result = { to: [data.address], feePerKb: 22000 }
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining(result), done)

  describe 'to', ->

    it 'should set an address', (done) ->
      payment.to(data.address)
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ to: [data.address] }), done)

    it 'should set multiple addresses', (done) ->
      payment.to(data.addresses)
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ to: data.addresses }), done)

    it 'should set to an account index', (done) ->
      payment.to(1)
      receiveAddress = hdwallet.accounts[1].receiveAddress
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ to: [receiveAddress] }), done)

    it 'should not set to an invalid account index', (done) ->
      payment.to(-1)
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ to: null }), done)

  describe 'from', ->

    it 'should set to an address ', (done) ->
      payment.from(data.address)
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ from: [data.address] }), done)

    it 'should set multiple addresses', (done) ->
      payment.from(data.addresses)
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ from: data.addresses }), done)

    it 'should set an account index', (done) ->
      payment.from(0)
      xpub = hdwallet.accounts[0].extendedPublicKey
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ from: [xpub] }), done)

    it 'should all addresses if no argument is specified', (done) ->
      payment.from()
      legacyAddresses = MyWallet.wallet.spendableActiveAddresses
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ from: legacyAddresses }), done)

    it 'should set the correct sweep amount and sweep fee', (done) ->
      payment.from(data.address)
      payment.payment.then((res) ->
        expect(res.sweepAmount).toEqual(19800)
        expect(res.sweepFee).toEqual(200)

        done()
      )

    it 'should set an address from a private key', (done) ->
      payment.from('5JrXwqEhjpVF7oXnHPsuddTc6CceccLRTfNpqU2AZH8RkPMvZZu') # PK for 12C5rBJ7Ev3YGBCbJPY6C8nkGhkUTNqfW9
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ from: data.addressesFromPk }), done)

    it 'should not set an address from an invalid string', (done) ->
      payment.from('1badaddresss')
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ from: null, change: null }), done)

  describe 'amount', ->

    it 'should not set negative amounts', (done) ->
      payment.amount(-1)
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ amounts: null }), done)

    it 'should not set amounts that aren\'t positive integers', (done) ->
      payment.amount('100000000')
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ amounts: null }), done)

    it 'should not set amounts if an element of the array is invalid', (done) ->
      payment.amount([10000, 20000, 30000, "324345"])
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ amounts: null }), done)

    it 'should set amounts from a valid number', (done) ->
      payment.amount(3000)
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ amounts: [3000] }), done)

    it 'should set amounts from a valid number array', (done) ->
      payment.amount([3000, 20000])
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ amounts: [3000, 20000] }), done)

  describe 'fee', ->

    it 'should not set a non positive integer fee', (done) ->
      payment.fee(-3000)
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ forcedFee: null }), done)

    it 'should not set a string fee', (done) ->
      payment.fee('3000')
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ forcedFee: null }), done)

    it 'should set a valid fee', (done) ->
      payment.fee(31337)
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ forcedFee: 31337 }), done)

  describe 'note', ->

    it 'should not set a non string note', (done) ->
      payment.note(1234)
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ note: null }), done)

    it 'should set a valid note', (done) ->
      payment.note('this is a valid note')
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ note: 'this is a valid note' }), done)

  describe 'feePerKb', ->
    beforeEach ->
      spyOn(Payment, "computeSuggestedSweep").and.callFake (coins, feePerKb) ->
        [8780, 11220]

    it 'should set to a positive value', (done) ->
      payment.feePerKb(22000)
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ feePerKb: 22000 }), done)

    it 'should not set to a negative value', (done) ->
      payment.feePerKb(-10000)
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining({ feePerKb: null }), done)

    it 'should use the feePerKb when setting sweep values', (done) ->
      payment.feePerKb(30000)
      payment.from(data.address)
      result = { sweepAmount: 8780, sweepFee: 11220 }
      expect(payment.payment).toBeResolvedWith(jasmine.objectContaining(result), done)


  describe 'computeSuggestedSweep', ->

    it 'should return amount = 0 when spending less than the fee', ->
      coins = [{ value: 1 }, { value: 2 }]

      res = Payment.computeSuggestedSweep(coins, 10000)
      expect(res[0]).toEqual(0)

    it 'should return amount = 0 and fee = 0 when no coins are provided', ->
      res = Payment.computeSuggestedSweep([], 10000)
      expect(res[0]).toEqual(0)
      expect(res[1]).toEqual(0)

    it 'should return amount = 0 and fee = 0 when bad input is provided', ->

      res = Payment.computeSuggestedSweep(null, 10000)
      expect(res[0]).toEqual(0)
      expect(res[1]).toEqual(0)

      res = Payment.computeSuggestedSweep(undefined, 10000)
      expect(res[0]).toEqual(0)
      expect(res[1]).toEqual(0)

#      res = Payment.computeSuggestedSweep([{ valueeeeee: 1 }], 10000)
#      expect(res[0]).toEqual(0)
#      expect(res[1]).toEqual(0)

    describe "when no fee is provided", ->

      beforeEach ->
        spyOn(Helpers, 'guessFee')

      it 'should use the wallet default fee', ->
        MyWallet.wallet.fee_per_kb = 1
        coins = [{ value: 100000 }]
        Payment.computeSuggestedSweep(coins)

        expect(Helpers.guessFee).toHaveBeenCalledWith(jasmine.anything(), jasmine.anything(), 1)

    it "fee + spendable balance should equal the sum of unspent outputs ", ->
      coins = [{ value: 10000 }, { value: 20000 }]

      res = Payment.computeSuggestedSweep(coins, 10000)

      expect(res[0] + res[1]).toEqual(30000)

    it "fee should equal Helpers.guessFee", ->
      coins = [{ value: 10000 }, { value: 20000 }]

      res = Payment.computeSuggestedSweep(coins, 10000)

      expect(res[1]).toEqual(200)

    it "fee should equal Helpers.guessFee whatever the order of the coins", ->
      coins = [{ value: 20000 }, { value: 10000 }]

      res = Payment.computeSuggestedSweep(coins, 10000)

      expect(res[1]).toEqual(200)

    it "should ignore outputs lower than the fee they add to the transactions", ->
      coins = [{ value: 10000 }, { value: 99 }]

      res = Payment.computeSuggestedSweep(coins, 10000)

      expect(res[0]).toEqual(9900)

    it "should not ignore outputs larger than the fee they add to the transactions", ->
      coins = [{ value: 10000 }, { value: 101 }]

      res = Payment.computeSuggestedSweep(coins, 10000)

      expect(res[0]).toEqual(9901)
