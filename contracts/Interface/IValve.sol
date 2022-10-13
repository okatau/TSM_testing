// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title IValve
/// @author FormalCrypto

import "@openzeppelin/contracts/access/IAccessControl.sol";

/// @notice Interface for Valve contract for revenue share XLA system. 
/// @dev Designed to Revenue Share ERC20 Token.
interface IValve is IAccessControl{

    // Information about stream.
    struct Brook{
        address streamAddress;
        uint256 percent;
    }

    // @notice Add available token address, which would be sent.
    // @dev Add available token address, which would be sent. Only for user with DEFAULT_ADMIN_ROLE 
    // @param _token Added address of avaiable token
    function addAvaiableToken(address _token) external;

    // @notice Update available token addresses, which would be sent. 
    // @dev Update available token addresses, which would be sent. Only for user with DEFAULT_ADMIN_ROLE
    // @param _token Update addresses of avaiable tokens.
    function updateAvaiableTokens(address[] calldata _tokens) external;

    // @notice Update streams, which get ERC20 tokens in split. 
    // @dev Update streams, which get ERC20 tokens in split. Only for user with DEFAULT_ADMIN_ROLE
    // @param _brooks Array with Brook struct (address, percent) to send.
    function updateStreams(Brook[] calldata _brooks) external;

    // @notice Distribution of all ERC20 tokens on the balance in accordance with the shares of streams. 
    // @dev Distribution of all ERC20 tokens on the balance in accordance with the shares of streams. 
    function Split() external;
}