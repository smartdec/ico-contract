## Token Information
Token Name: PASS Token
Symbol: PASS  
Decimals: 18  
Total Supply: 1000000000 PASS  

## ICO
ICO Distributed Tokens: 250000000 PASS
Base Rate: 1 ETH = 10000 PASS
Hard cap: 20000 ethers
Soft cap: 1000 ethers

## Build

```bash
npm install
npm run truffle compile
```

## Deploy
To deploy contracts to Ethereum network

Edit `truffle-config.js` for proper network, like:
```js
module.exports = {
  networks: {
    ropsten:  {
      network_id: 3,
      host: "192.168.88.242",
      port:  8546,
      gas:   4600000,
      gasPrice: 5000000000
    }
    ...
```

And run
```bash
npm run truffle migrate
```

## Test (Unix only)
To run test run
```bash
npm run test
```

## Coverage (Unix only)
To run test coverage run

```bash
npm run coverage
```
