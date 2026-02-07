// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {TestUSDC} from "../src/TestUSDC.sol";

/// @notice Deploy Test USDC to Arbitrum Sepolia. Use the logged address as SETTLEMENT_TOKEN.
/// Run with: forge script script/DeployTestUSDC.s.sol:DeployTestUSDCScript --rpc-url arbitrum_sepolia --broadcast --private-key $PRIVATE_KEY
contract DeployTestUSDCScript is Script {
    function run() external returns (TestUSDC token) {
        uint256 initialSupply = vm.envOr("TEST_USDC_INITIAL_MINT", uint256(1_000_000e6));

        vm.startBroadcast();
        token = new TestUSDC();
        token.mint(token.owner(), initialSupply);
        vm.stopBroadcast();

        console.log("TestUSDC deployed at", address(token));
        console.log("Minted", initialSupply / 1e6, "USDC (6 decimals) to", token.owner());
        console.log("Use as SETTLEMENT_TOKEN for Settlement deploy");
    }
}
