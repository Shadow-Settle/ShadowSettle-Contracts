// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {Settlement} from "../src/Settlement.sol";
import {MockERC20} from "./MockERC20.sol";

contract SettlementTest is Test {
    Settlement public settlement;
    MockERC20 public token;

    address public executor;
    address public alice;
    address public bob;
    address public carol;

    function setUp() public {
        token = new MockERC20();
        executor = makeAddr("executor");
        alice = makeAddr("alice");
        bob = makeAddr("bob");
        carol = makeAddr("carol");

        settlement = new Settlement(address(token), executor);

        token.mint(alice, 1000e6);
    }

    function test_Deposit() public {
        vm.startPrank(alice);
        token.approve(address(settlement), 100e6);
        settlement.deposit(100e6);
        vm.stopPrank();

        assertEq(token.balanceOf(address(settlement)), 100e6);
    }

    function test_SettleBatch() public {
        vm.prank(alice);
        token.approve(address(settlement), 100e6);
        vm.prank(alice);
        settlement.deposit(100e6);

        address[] memory recipients = new address[](2);
        recipients[0] = bob;
        recipients[1] = carol;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 40e6;
        amounts[1] = 60e6;
        bytes memory attestation = abi.encodePacked("tee-attestation-hash-1");

        vm.prank(executor);
        settlement.settleBatch(recipients, amounts, attestation);

        assertEq(token.balanceOf(bob), 40e6, "bob balance");
        assertEq(token.balanceOf(carol), 60e6, "carol balance");
        assertEq(token.balanceOf(address(settlement)), 0);
    }

    function test_RevertWhenSettleBatch_NotExecutor() public {
        vm.prank(alice);
        token.approve(address(settlement), 100e6);
        vm.prank(alice);
        settlement.deposit(100e6);

        address[] memory recipients = new address[](1);
        recipients[0] = bob;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 50e6;
        bytes memory attestation = abi.encodePacked("attestation");

        vm.prank(alice);
        vm.expectRevert(Settlement.OnlyExecutor.selector);
        settlement.settleBatch(recipients, amounts, attestation);
    }

    function test_RevertWhenSettleBatch_ReplayAttestation() public {
        vm.prank(alice);
        token.approve(address(settlement), 200e6);
        vm.prank(alice);
        settlement.deposit(200e6);

        address[] memory recipients = new address[](1);
        recipients[0] = bob;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 50e6;
        bytes memory attestation = abi.encodePacked("same-attestation");

        vm.startPrank(executor);
        settlement.settleBatch(recipients, amounts, attestation);
        vm.expectRevert(Settlement.AttestationAlreadyUsed.selector);
        settlement.settleBatch(recipients, amounts, attestation);
        vm.stopPrank();
    }

    function test_RevertWhenSettleBatch_LengthMismatch() public {
        vm.prank(alice);
        token.approve(address(settlement), 100e6);
        vm.prank(alice);
        settlement.deposit(100e6);

        address[] memory recipients = new address[](2);
        recipients[0] = bob;
        recipients[1] = carol;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100e6;
        bytes memory attestation = abi.encodePacked("attestation");

        vm.prank(executor);
        vm.expectRevert(Settlement.LengthMismatch.selector);
        settlement.settleBatch(recipients, amounts, attestation);
    }

    function test_RevertWhenSettleBatch_InsufficientBalance() public {
        vm.prank(alice);
        token.approve(address(settlement), 50e6);
        vm.prank(alice);
        settlement.deposit(50e6);

        address[] memory recipients = new address[](1);
        recipients[0] = bob;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100e6;
        bytes memory attestation = abi.encodePacked("attestation");

        vm.prank(executor);
        vm.expectRevert(Settlement.InsufficientBalance.selector);
        settlement.settleBatch(recipients, amounts, attestation);
    }

    function test_IsAttestationUsed() public {
        bytes memory attestation = abi.encodePacked("my-attestation");
        assertFalse(settlement.isAttestationUsed(attestation));

        vm.prank(alice);
        token.approve(address(settlement), 10e6);
        vm.prank(alice);
        settlement.deposit(10e6);

        address[] memory recipients = new address[](1);
        recipients[0] = bob;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10e6;

        vm.prank(executor);
        settlement.settleBatch(recipients, amounts, attestation);

        assertTrue(settlement.isAttestationUsed(attestation));
    }

    function test_SetExecutor() public {
        address newExecutor = makeAddr("newExecutor");
        vm.prank(executor);
        settlement.setExecutor(newExecutor);
        assertEq(settlement.executor(), newExecutor);

        vm.prank(alice);
        token.approve(address(settlement), 10e6);
        vm.prank(alice);
        settlement.deposit(10e6);

        address[] memory recipients = new address[](1);
        recipients[0] = bob;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 10e6;
        bytes memory attestation = abi.encodePacked("attestation-v2");

        vm.prank(newExecutor);
        settlement.settleBatch(recipients, amounts, attestation);
        assertEq(token.balanceOf(bob), 10e6, "bob balance after new executor");
    }

    function test_RevertWhenSetExecutor_NotExecutor() public {
        vm.prank(alice);
        vm.expectRevert(Settlement.OnlyExecutor.selector);
        settlement.setExecutor(makeAddr("other"));
    }
}
