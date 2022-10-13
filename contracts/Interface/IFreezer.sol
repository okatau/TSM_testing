// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title IFreezer
/// @author FormalCrypto

/// @notice Interface for Freezer contract
/// @dev Interface for Freezer contract
interface IFreezer {

    /// @notice Changing TSM address for flexible update Token Sale Machine contract.
    /// @dev Reset address for Token Sale Machine.
    /// @param newTSM New address for Token Sale Machine.
    function changeTSM(address newTSM) external;

    /// @notice Add user address and his balance of XLA token which may be claimed after verification in Token Sale Machine.
    /// @dev This method can only call TSM.
    /// @param claimer It's referral address, which wasn't be verified but use in referal program.
    function addClaimer(address claimer) external;

    /// @notice Withdraw XLA Token from Freezer contract.
    /// @dev This method can only call verifiyed user with non zero value for claim.
    function withdraw() external;
}