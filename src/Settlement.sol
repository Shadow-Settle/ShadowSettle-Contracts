// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {IERC20} from "forge-std/interfaces/IERC20.sol";

/// @title Settlement
/// @notice Holds funds and executes batch payouts. No eligibility or payout logic on-chain.
/// @dev Only the executor (e.g. backend after TEE verification) may call settleBatch.
contract Settlement {
    IERC20 public immutable token;
    address public executor;

    /// @notice Per-user balance (deposits minus withdrawals). Pool total used for settleBatch.
    mapping(address => uint256) public balanceOf;
    /// @notice Total tokens held for depositors (deposits minus withdrawals minus settled).
    uint256 public totalPool;

    mapping(bytes32 => bool) public usedAttestations;

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);
    event BatchSettled(bytes32 indexed attestationHash, uint256 recipientCount, uint256 totalAmount);
    event ExecutorUpdated(address indexed previousExecutor, address indexed newExecutor);

    error OnlyExecutor();
    error AttestationAlreadyUsed();
    error LengthMismatch();
    error InsufficientBalance();
    error ZeroAddress();
    error ZeroLength();

    modifier onlyExecutor() {
        if (msg.sender != executor) revert OnlyExecutor();
        _;
    }

    /// @param _token ERC20 token used for payouts (e.g. USDC).
    /// @param _executor Address allowed to call settleBatch (backend/coordinator).
    constructor(address _token, address _executor) {
        if (_token == address(0) || _executor == address(0)) revert ZeroAddress();
        token = IERC20(_token);
        executor = _executor;
    }

    /// @notice Deposit tokens into the settlement pool. Caller must have approved this contract.
    /// @param amount Amount of token to deposit.
    function deposit(uint256 amount) external {
        if (amount == 0) return;
        bool ok = token.transferFrom(msg.sender, address(this), amount);
        require(ok, "Settlement: transfer failed");
        balanceOf[msg.sender] += amount;
        totalPool += amount;
        emit Deposited(msg.sender, amount);
    }

    /// @notice Withdraw your deposited tokens back to your wallet.
    /// @param amount Amount to withdraw.
    function withdraw(uint256 amount) external {
        if (amount == 0) return;
        if (balanceOf[msg.sender] < amount) revert InsufficientBalance();
        balanceOf[msg.sender] -= amount;
        totalPool -= amount;
        bool ok = token.transfer(msg.sender, amount);
        require(ok, "Settlement: transfer failed");
        emit Withdrawn(msg.sender, amount);
    }

    /// @notice Execute a batch payout. Only executor may call; attestation must not have been used.
    /// @param recipients Array of recipient addresses.
    /// @param amounts Array of amounts (same length as recipients).
    /// @param attestation TEE attestation proof (used only for replay protection; not verified on-chain).
    function settleBatch(address[] calldata recipients, uint256[] calldata amounts, bytes calldata attestation)
        external
        onlyExecutor
    {
        if (recipients.length == 0) revert ZeroLength();
        if (recipients.length != amounts.length) revert LengthMismatch();

        bytes32 attestationHash = keccak256(attestation);
        if (usedAttestations[attestationHash]) revert AttestationAlreadyUsed();
        usedAttestations[attestationHash] = true;

        uint256 total;
        for (uint256 i; i < amounts.length;) {
            total += amounts[i];
            unchecked {
                ++i;
            }
        }

        if (totalPool < total) revert InsufficientBalance();
        totalPool -= total;

        if (token.balanceOf(address(this)) < total) revert InsufficientBalance();

        for (uint256 i; i < recipients.length;) {
            if (amounts[i] > 0) {
                bool ok = token.transfer(recipients[i], amounts[i]);
                require(ok, "Settlement: transfer failed");
            }
            unchecked {
                ++i;
            }
        }

        emit BatchSettled(attestationHash, recipients.length, total);
    }

    /// @notice Update the executor address. Only current executor may update.
    /// @param _executor New executor address.
    function setExecutor(address _executor) external onlyExecutor {
        if (_executor == address(0)) revert ZeroAddress();
        address previous = executor;
        executor = _executor;
        emit ExecutorUpdated(previous, _executor);
    }

    /// @notice Check whether an attestation has already been used (replay check).
    function isAttestationUsed(bytes calldata attestation) external view returns (bool) {
        return usedAttestations[keccak256(attestation)];
    }
}
