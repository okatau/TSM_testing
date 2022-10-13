// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Verifiyer
/// @author FormalCrypto

import "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice Create for administrate Token Sale Machine.
/// @dev Inherited by contract TokenSaleMachine.
contract Verifiyer is AccessControl{
    // Verifiyed user addresses
    mapping (address => bool) public verified;
    // Avaiable stable coin addresses. (1 Token = 1 USD)
    mapping (address => bool) public avaiableStableCoin;
    // Role to verifiyed users
    bytes32 private USER_REGISTER_ROLE = keccak256("USER_REGISTER_ROLE");
    // Role to change avaiable tokens list
    bytes32 private TOKEN_REGISTER_ROLE = keccak256("TOKEN_REGISTER_ROLE");

    modifier onlyVerifiedToken(address _token){
        require (avaiableStableCoin[_token], "Token is not avaiable to pay with");
        _;
    }

    /// @notice Add verifiyed user into whitelist.
    ///         Verifiyed users can buy XLA token.
    /// @dev Only for users with USER_REGISTER_ROLE.
    /// @param user Verifiyed address.
    function addUser(address user) external onlyRole(USER_REGISTER_ROLE) {
            verified[user] = true;
    }

    /// @notice Add verifiyed users into whitelist.
    ///         Verifiyed users can buy XLA token.
    /// @dev Only for users with USER_REGISTER_ROLE.
    /// @param _users Verifiyed addresses.
    function addUsers(address[] calldata _users) external onlyRole(USER_REGISTER_ROLE) {
        for(uint256 i; i < _users.length; i++)
            verified[_users[i]] = true;
    }

    /// @notice Remove verifiyed users from whitelist.
    /// @dev Only for users with USER_REGISTER_ROLE.
    /// @param _users Remove addresses.
    function removeUsers(address[] calldata _users) external onlyRole(USER_REGISTER_ROLE) {
        for(uint256 i; i < _users.length; i++)
            verified[_users[i]] = false;
    }

    /// @notice Add accepted stable coins.
    ///         With 'Avaiable stable coins' can be paid for XLA token. 
    /// @dev Only for users with TOKEN_REGISTER_ROLE.
    /// @param tokens Accepted tokens.
    function addStableCoins(address[] calldata tokens) external onlyRole(TOKEN_REGISTER_ROLE) {
        for(uint256 i; i < tokens.length; i++)
            avaiableStableCoin[tokens[i]] = true;
    }

    /// @notice Remove accepted stable coins.
    /// @dev Remove accepted stable coins. Only for users with TOKEN_REGISTER_ROLE.
    /// @param tokens Removed tokens.
    function removeStableCoins(address[] calldata tokens) external onlyRole(TOKEN_REGISTER_ROLE) {
        for(uint256 i; i < tokens.length; i++)
            avaiableStableCoin[tokens[i]] = false;
    }
}