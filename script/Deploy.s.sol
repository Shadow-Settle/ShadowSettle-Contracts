// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Script, console} from "forge-std/Script.sol";
import {Settlement} from "../src/Settlement.sol";
import {TestUSDC} from "../src/TestUSDC.sol";
import {MockERC20} from "../test/MockERC20.sol";

/// Run with: forge script script/Deploy.s.sol:DeployScript --rpc-url arbitrum_sepolia --broadcast --private-key $PRIVATE_KEY
contract DeployScript is Script {
    function run() external returns (Settlement settlement) {
        address token = vm.envOr("SETTLEMENT_TOKEN", address(0));
        address executor = vm.envOr("SETTLEMENT_EXECUTOR", address(0));

        vm.startBroadcast();
        if (token == address(0)) {
            uint256 useTestUSDC = vm.envOr("USE_TEST_USDC", uint256(1));
            if (useTestUSDC != 0) {
                TestUSDC testToken = new TestUSDC();
                testToken.mint(testToken.owner(), 1_000_000e6);
                token = address(testToken);
                if (executor == address(0)) executor = testToken.owner();
                console.log("TestUSDC (deployed) at", token);
            } else {
                MockERC20 mockToken = new MockERC20();
                mockToken.mint(tx.origin, 1_000_000e6);
                token = address(mockToken);
                if (executor == address(0)) executor = tx.origin;
                console.log("MockERC20 (local) at", token);
            }
        } else if (executor == address(0)) {
            executor = tx.origin;
        }
        settlement = new Settlement(token, executor);
        console.log("Settlement at", address(settlement));
        vm.stopBroadcast();
    }
}
