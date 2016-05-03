Bitcoin = require('bitcoinjs-lib')
ECPair = Bitcoin.ECPair
BigInteger = require('bigi')

ImportExport = require('../src/import-export')
WalletCrypto = require('../src/wallet-crypto')


describe "BIP38", ->

  observer =
    success: (key) ->
    wrong_password: () ->
    error: (err) ->

  beforeEach ->
    # overrride as a temporary solution
    window.setTimeout = (myFunction) -> myFunction()

    # TODO: figure out how to use ECPair.fromPublicKeyBuffer and reenable
    # public key caching in tests
    localStorage.clear()

    # mock used inside parseBIP38toECPair
    spyOn(WalletCrypto, "scrypt").and.callFake(
      (password, salt, N, r, p, dkLen, callback) ->
        # preimages of Crypto_scrypt
        wrongPassword = "WRONG_PASSWORD" + "e957a24a" + "16384" + "8" + "8" + "64"
        testVector1 = "TestingOneTwoThree" + "e957a24a" + "16384" + "8" + "8" + "64"
        testVector2 = "Satoshi" + "572e117e" + "16384" + "8" + "8" + "64"
        # testVector3 = "ϓ␀𐐀💩" + "f4e775a8" + "16384" + "8" + "8" + "64"
        testVector3 = 'ϓ\u0000𐐀💩' + "f4e775a8" + "16384" + "8" + "8" + "64"
        testVector4 = "TestingOneTwoThree" + "43be4179" + "16384" + "8" + "8" + "64"
        testVector5 = "Satoshi" + "26e017d2" + "16384" + "8" + "8" + "64"
        testVector6 = "TestingOneTwoThree" + "a50dba6772cb9383" + "16384" + "8" + "8" + "32"
        testVector61 = "020eac136e97ce6bf3e2bceb65d906742f7317b6518c54c64353c43dcc36688c47" +
                       "62b5b722a50dba6772cb9383" + "1024"+"1"+"1"+"64"
        testVector7 = "Satoshi" + "67010a9573418906" + "16384" + "8" + "8" + "32"
        testVector71 = "022413a674b5bceab5abe0b14ce44dfa7fc6b55ecdbed88e7c50c0b4e953f1e05e" +
                       "059a548167010a9573418906" + "1024"+"1"+"1"+"64"
        testVector8 = "MOLON LABE" + "4fca5a97" + "16384" + "8" + "8" + "32"
        testVector81 = "02a6bf1824208903aa344833d614f7fa3ba46f4f8d57b2e219a1cfac961a9b7395" +
                       "bb458cef4fca5a974040f001" + "1024"+"1"+"1"+"64"
        testVector9 = "ΜΟΛΩΝ ΛΑΒΕ" + "c40ea76f" + "16384" + "8" + "8" + "32"
        testVector91 = "030a7a6f6536951f1cdf450e9ef6c1f615b904af58f7c17598cec3274e6769d3ef" +
                       "494af136c40ea76fc501a001" + "1024"+"1"+"1"+"64"
        # images of Crypto_scrypt
        Crypto_scrypt_cache = {}
        Crypto_scrypt_cache[wrongPassword] =
          Buffer "e39fc025591c26f6ebd47077b869958fedcb88df623fd6743fab116fefac0a4e1d\
                  13216d5e4294d15fd79772b8a91da612a030935ec30aa4f97c0adee73539a6","hex"
        Crypto_scrypt_cache[testVector1] =
          Buffer "f87648a6b42fdd86ef6837a249cde15318f264d43a859b610e78ea63d51cb2d3e6\
                  0bf44bfb29d543bba24afcccfadbfc6ef9312fcccf589fa5ea1366ec21e4c0","hex"
        Crypto_scrypt_cache[testVector2] =
          Buffer "02d4a6b94240bd1cdaa6773f430e43a0d9a8cbc9a83b044998f7ef2e3f31a4de7f\
                  2436fede417c46b988879f4ef0595b75a55bcaec27848ef94e9f4b4d684cb9","hex"
        # Crypto_scrypt_cache[testVector3] =
        #   Buffer "0e271b33f58006bbdc84850456f508cffc661f26909462995b041d31ad35ef87a1\
        #           2871a5c5e9a6b3bc8e8c3f2eb195d17e2559f38b71cba32337d742d7761f5c","hex"
        Crypto_scrypt_cache[testVector3] =
          Buffer "981726c732b25e1eede74a32ba72fd113144c52d2eadc0f4bb12ec9ccb2e05cfc257\
                  9a6c3280d21cee2e2e6b4bf23d3b8cf2a39574b942e6f9f4381659db4c6f","hex"
        Crypto_scrypt_cache[testVector4] =
          Buffer "731ef3c737b55df4998b44fa8a547a3f38df424da240de389b11d1875ba477672f\
                  2fe81b0532b5950e3ea6fff92c65d467aa7d054969821de2344f7a86d42569","hex"
        Crypto_scrypt_cache[testVector5] =
          Buffer "0478e3e18d96ae2fbe033e3261944670c0ead16336890e4af46f55851ae211d22c\
                  97d288383bfd14983e5c574dafeb66f31b16bad037d40a6467019840ffa323","hex"
        Crypto_scrypt_cache[testVector6] =
          Buffer "c8ff7a1c8c8898a0361e477fa8f0f05c00d07c5d9626f00b03c0140a307c98f4","hex"
        Crypto_scrypt_cache[testVector61] =
          Buffer "da2d320e2ca088575369601e94dd71f210fc69c047a3d0f48bdbaab595916dc7b8\
                  d083ea2678b5a71558c0fb0efa58b565227d05adf0c25fa0b9a74755477827","hex"
        Crypto_scrypt_cache[testVector7] =
          Buffer "e8a9722cf7988c31f929bd656085ca6470595e068bae22858ea7d84fb4197a99","hex"
        Crypto_scrypt_cache[testVector71] =
          Buffer "dc7d942ea3c6c8953b30ee010c147a3222f6f5c52923e28185832f64d86781bc51\
                  20c42e25509460892ac9fec45e1bc52613238e1b5c1ead9d41bdeea8892c5c","hex"
        Crypto_scrypt_cache[testVector8] =
          Buffer "7f5aee1a080d9e84f4ddf31f8b78356f472c03ac95bff320789d50137e66f279","hex"
        Crypto_scrypt_cache[testVector81] =
          Buffer "a8bc4ad35fb69cc37f129abb458245e4523c97133b22a5cad88035f99d0b1d50ff\
                  c8317a1eaea330e1e17305539ec5c5ce36168a35d6d13fefa21d5e2cb1c1e9","hex"
        Crypto_scrypt_cache[testVector9] =
          Buffer "147562b11c3a361365d89c1a2e5bed186c43c3c2d964632d17b2a56f96fc3110","hex"
        Crypto_scrypt_cache[testVector91] =
          Buffer "1471d24b21c21e164f48237e9a5f0926493bf6118373a0d2e18387a7c345646d68\
                  89d2c30be9721874f10844fb98794de1caba62bb659a51492d4f33ca3237d7","hex"
        keyTest = password.toString("hex") + salt.toString("hex") + (N).toString() +
                  (r).toString() + (p).toString() + (dkLen).toString()
        Image = Crypto_scrypt_cache[keyTest]
        if Image?
          callback Image
        else
          throw "Input not cached in crypto_scrypt mock function"
          callback null
    )

  describe "parseBIP38toECPair()", ->
    beforeEach ->
      Bitcoin.ECPair.originalFromWIF = Bitcoin.ECPair.fromWIF
      spyOn(Bitcoin.ECPair, "fromWIF").and.callFake((wif)->
        key = undefined

        if hex = localStorage.getItem("Bitcoin.ECPair.fromWIF " + wif)
          buffer = new Buffer(hex, "hex")
          key = {
            d: BigInteger.fromBuffer(buffer)
          }
        else
          key = Bitcoin.ECPair.originalFromWIF(wif)
          hex = key.d.toBuffer().toString('hex')
          localStorage.setItem("Bitcoin.ECPair.fromWIF " + wif, hex)

        key
      )

      Bitcoin.originalECPair = Bitcoin.ECPair
      spyOn(Bitcoin, "ECPair").and.callFake((d, Q, options={}) ->
        cacheKey = "Bitcoin.ECPair " + d.toBuffer().toString('hex') + " " + options.compressed
        pubKey = undefined
        if hex = localStorage.getItem(cacheKey)
          console.log("Cache hit: ", hex)
          key  = Bitcoin.originalECPair.fromPublicKeyBuffer(Buffer(hex))
          key.d = d
        else
          key  = new Bitcoin.originalECPair(d, null, {compressed: options.compressed})
          hex = key.getPublicKeyBuffer().toString("hex")
          # console.log("Cache miss: ", hex)
          localStorage.setItem(cacheKey, hex)

        address = key.getAddress()
        wif = key.toWIF()
        pubKeyBuffer = key.getPublicKeyBuffer()

        {
          d: d
          getPublicKeyBuffer: () -> pubKeyBuffer
          toWIF: () -> wif
          getAddress: () -> address
        }
      )

    it "when called with correct password should fire success with the right params", ->

      pw = "TestingOneTwoThree"
      pk = "6PRVWUbkzzsbcVac2qwfssoUJAN1Xhrg6bNk8J7Nzm5H7kxEbn2Nh2ZoGg"
      spyOn(observer, "success")
      spyOn(observer, "wrong_password")

      k = Bitcoin.ECPair
            .fromWIF "5KN7MzqK5wt2TP1fQCYyHBtDrXdJuXbUzm4A9rKAteGu3Qi5CVR"

      # Not needed:
      # k.pub.Q._zInv = k.pub.Q.z.modInverse k.pub.Q.curve.p unless k.pub.Q._zInv?

      ImportExport.parseBIP38toECPair  pk ,pw ,observer.success, observer.wrong_password

      expect(WalletCrypto.scrypt).toHaveBeenCalled()

      # Doesn't work:
      # expect(observer.success).toHaveBeenCalledWith(k)

      expect(observer.success).toHaveBeenCalled()

      expect(observer.success.calls.argsFor(0)[0].d).toEqual(k.d)

      expect(observer.wrong_password).not.toHaveBeenCalled()

    it "when called with wrong password should fire wrong_password", ->

      spyOn(observer, "success")
      spyOn(observer, "wrong_password")
      pw = "WRONG_PASSWORD"
      pk = "6PRVWUbkzzsbcVac2qwfssoUJAN1Xhrg6bNk8J7Nzm5H7kxEbn2Nh2ZoGg"

      ImportExport.parseBIP38toECPair  pk ,pw ,observer.success ,observer.wrong_password

      expect(observer.wrong_password).toHaveBeenCalled()

    it "(testvector1) No compression, no EC multiply, Test 1 , should work", ->

      spyOn(observer, "success")
      spyOn(observer, "wrong_password")
      expectedWIF = "5KN7MzqK5wt2TP1fQCYyHBtDrXdJuXbUzm4A9rKAteGu3Qi5CVR"
      expectedCompression = false;
      pw = "TestingOneTwoThree"
      pk = "6PRVWUbkzzsbcVac2qwfssoUJAN1Xhrg6bNk8J7Nzm5H7kxEbn2Nh2ZoGg"

      ImportExport.parseBIP38toECPair  pk ,pw ,observer.success ,observer.wrong_password
      computedWIF = observer.success.calls.argsFor(0)[0].toWIF()
      computedCompression = observer.success.calls.argsFor(0)[1]

      expect(observer.wrong_password).not.toHaveBeenCalled()
      expect(computedWIF).toEqual(expectedWIF)
      expect(computedCompression).toEqual(expectedCompression)

    it "(testvector2) No compression, no EC multiply, Test 2, should work", ->

      spyOn(observer, "success")
      spyOn(observer, "wrong_password")
      expectedWIF = "5HtasZ6ofTHP6HCwTqTkLDuLQisYPah7aUnSKfC7h4hMUVw2gi5"
      expectedCompression = false;
      pw = "Satoshi"
      pk = "6PRNFFkZc2NZ6dJqFfhRoFNMR9Lnyj7dYGrzdgXXVMXcxoKTePPX1dWByq"

      ImportExport.parseBIP38toECPair  pk ,pw ,observer.success ,observer.wrong_password
      computedWIF = observer.success.calls.argsFor(0)[0].toWIF()
      computedCompression = observer.success.calls.argsFor(0)[1]

      expect(observer.wrong_password).not.toHaveBeenCalled()
      expect(computedWIF).toEqual(expectedWIF)
      expect(computedCompression).toEqual(expectedCompression)

    xit "(testvector3) No compression, no EC multiply, Test 3, should work", ->

      spyOn(observer, "success")
      spyOn(observer, "wrong_password")

      pw = String.fromCodePoint(0x03d2, 0x0301, 0x0000, 0x00010400, 0x0001f4a9)
      pk = "6PRW5o9FLp4gJDDVqJQKJFTpMvdsSGJxMYHtHaQBF3ooa8mwD69bapcDQn"
      k = Bitcoin.ECPair
            .fromWIF "5Jajm8eQ22H3pGWLEVCXyvND8dQZhiQhoLJNKjYXk9roUFTMSZ4"
      # k.pub.Q._zInv = k.pub.Q.z.modInverse k.pub.Q.curve.p unless k.pub.Q._zInv?
      ImportExport.parseBIP38toECPair  pk ,pw ,observer.success ,observer.wrong_password

      expect(observer.wrong_password).not.toHaveBeenCalled()
      expect(observer.success.calls.argsFor(0)[0].d).toEqual(k.d)

    it "(testvector4) Compression, no EC multiply, Test 1, should work", ->

      spyOn(observer, "success")
      spyOn(observer, "wrong_password")
      expectedWIF = "L44B5gGEpqEDRS9vVPz7QT35jcBG2r3CZwSwQ4fCewXAhAhqGVpP"
      expectedCompression = true;
      pw = "TestingOneTwoThree"
      pk = "6PYNKZ1EAgYgmQfmNVamxyXVWHzK5s6DGhwP4J5o44cvXdoY7sRzhtpUeo"

      ImportExport.parseBIP38toECPair  pk ,pw ,observer.success ,observer.wrong_password
      computedWIF = observer.success.calls.argsFor(0)[0].toWIF()
      computedCompression = observer.success.calls.argsFor(0)[1]

      expect(observer.wrong_password).not.toHaveBeenCalled()
      expect(computedWIF).toEqual(expectedWIF)
      expect(computedCompression).toEqual(expectedCompression)

    it "(testvector5) Compression, no EC multiply, Test 2, should work", ->

      spyOn(observer, "success")
      spyOn(observer, "wrong_password")
      expectedWIF = "KwYgW8gcxj1JWJXhPSu4Fqwzfhp5Yfi42mdYmMa4XqK7NJxXUSK7"
      expectedCompression = true;
      pw = "Satoshi"
      pk = "6PYLtMnXvfG3oJde97zRyLYFZCYizPU5T3LwgdYJz1fRhh16bU7u6PPmY7"

      ImportExport.parseBIP38toECPair  pk ,pw ,observer.success ,observer.wrong_password
      computedWIF = observer.success.calls.argsFor(0)[0].toWIF()
      computedCompression = observer.success.calls.argsFor(0)[1]

      expect(observer.wrong_password).not.toHaveBeenCalled()
      expect(computedWIF).toEqual(expectedWIF)
      expect(computedCompression).toEqual(expectedCompression)

    it "(testvector6) No compression, EC multiply, no lot/sequence numbers, Test 1, should work", ->

      spyOn(observer, "success")
      spyOn(observer, "wrong_password")
      expectedWIF = "5K4caxezwjGCGfnoPTZ8tMcJBLB7Jvyjv4xxeacadhq8nLisLR2"
      expectedCompression = false;
      pw = "TestingOneTwoThree"
      pk = "6PfQu77ygVyJLZjfvMLyhLMQbYnu5uguoJJ4kMCLqWwPEdfpwANVS76gTX"

      ImportExport.parseBIP38toECPair  pk ,pw ,observer.success ,observer.wrong_password
      computedWIF = observer.success.calls.argsFor(0)[0].toWIF()
      computedCompression = observer.success.calls.argsFor(0)[1]

      expect(observer.wrong_password).not.toHaveBeenCalled()
      expect(computedWIF).toEqual(expectedWIF)
      expect(computedCompression).toEqual(expectedCompression)

    it "(testvector7) No compression, EC multiply, no lot/sequence numbers, Test 2, should work", ->

      spyOn(observer, "success")
      spyOn(observer, "wrong_password")
      expectedWIF = "5KJ51SgxWaAYR13zd9ReMhJpwrcX47xTJh2D3fGPG9CM8vkv5sH"
      expectedCompression = false;
      pw = "Satoshi"
      pk = "6PfLGnQs6VZnrNpmVKfjotbnQuaJK4KZoPFrAjx1JMJUa1Ft8gnf5WxfKd"

      ImportExport.parseBIP38toECPair  pk ,pw ,observer.success ,observer.wrong_password
      computedWIF = observer.success.calls.argsFor(0)[0].toWIF()
      computedCompression = observer.success.calls.argsFor(0)[1]

      expect(observer.wrong_password).not.toHaveBeenCalled()
      expect(computedWIF).toEqual(expectedWIF)
      expect(computedCompression).toEqual(expectedCompression)

    it "(testvector8) No compression, EC multiply, lot/sequence numbers, Test 1, should work", ->

      spyOn(observer, "success")
      spyOn(observer, "wrong_password")
      expectedWIF = "5JLdxTtcTHcfYcmJsNVy1v2PMDx432JPoYcBTVVRHpPaxUrdtf8"
      expectedCompression = false;
      pw = "MOLON LABE"
      pk = "6PgNBNNzDkKdhkT6uJntUXwwzQV8Rr2tZcbkDcuC9DZRsS6AtHts4Ypo1j"

      ImportExport.parseBIP38toECPair  pk ,pw ,observer.success ,observer.wrong_password
      computedWIF = observer.success.calls.argsFor(0)[0].toWIF()
      computedCompression = observer.success.calls.argsFor(0)[1]

      expect(observer.wrong_password).not.toHaveBeenCalled()
      expect(computedWIF).toEqual(expectedWIF)
      expect(computedCompression).toEqual(expectedCompression)

    it "(testvector9) No compression, EC multiply, lot/sequence numbers, Test 2, should work", ->

      spyOn(observer, "success")
      spyOn(observer, "wrong_password")
      expectedWIF = "5KMKKuUmAkiNbA3DazMQiLfDq47qs8MAEThm4yL8R2PhV1ov33D"
      expectedCompression = false;
      pw = "ΜΟΛΩΝ ΛΑΒΕ"
      pk = "6PgGWtx25kUg8QWvwuJAgorN6k9FbE25rv5dMRwu5SKMnfpfVe5mar2ngH"

      ImportExport.parseBIP38toECPair  pk ,pw ,observer.success ,observer.wrong_password
      computedWIF = observer.success.calls.argsFor(0)[0].toWIF()
      computedCompression = observer.success.calls.argsFor(0)[1]

      expect(observer.wrong_password).not.toHaveBeenCalled()
      expect(computedWIF).toEqual(expectedWIF)
      expect(computedCompression).toEqual(expectedCompression)
