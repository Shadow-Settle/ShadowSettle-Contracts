# shadowsettle_contracts

Solidity smart contracts for **ShadowSettle**: `Settlement` (deposit, withdraw, batch payout with attestation replay protection) and **TestUSDC** for Arbitrum Sepolia.

Part of the [ShadowSettle](https://github.com/ShadowSettle/ShadowSettle) monorepo. Built with **Foundry**.

Foundry consists of:

- **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
- **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
- **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
- **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

**Option A – Token only (then use address as `SETTLEMENT_TOKEN`)**  
Deploy Test USDC to Arbitrum Sepolia. **You must pass `--private-key`** so Forge uses your wallet (not the default Anvil account):

```shell
$ cd shadowsettle_contracts
$ source .env   # or: export PRIVATE_KEY=0x...
$ forge script script/DeployTestUSDC.s.sol:DeployTestUSDCScript --rpc-url arbitrum_sepolia --broadcast --verify --private-key $PRIVATE_KEY
# Optional: TEST_USDC_INITIAL_MINT=5000000e6 (default 1_000_000e6)
```

**Option B – Token + Settlement in one go**  
If `SETTLEMENT_TOKEN` is not set, the main script deploys TestUSDC, mints 1M to deployer, then deploys Settlement. **Pass `--private-key`**:

```shell
$ source .env
$ forge script script/Deploy.s.sol:DeployScript --rpc-url arbitrum_sepolia --broadcast --verify --private-key $PRIVATE_KEY
# Optional: SETTLEMENT_EXECUTOR=<addr> (default: deployer). USE_TEST_USDC=0 to use MockERC20 (local only).
```

**Option C – Settlement only (you already have a token)**  
Set `SETTLEMENT_TOKEN` to your TestUSDC (or any ERC20) address:

```shell
$ source .env
$ SETTLEMENT_TOKEN=<token_address> SETTLEMENT_EXECUTOR=<executor> forge script script/Deploy.s.sol:DeployScript --rpc-url arbitrum_sepolia --broadcast --verify --private-key $PRIVATE_KEY
```

Local (Anvil) – uses TestUSDC by default; key can be the default Anvil key:

```shell
$ forge script script/Deploy.s.sol:DeployScript --rpc-url http://127.0.0.1:8545 --broadcast --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
