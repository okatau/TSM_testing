// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Staking
/// @author FormalCrypto

import "@openzeppelin/contracts/access/IAccessControl.sol";

interface ITSM is IAccessControl{
   
    // @notice Change VALVE address.
    // @dev This method can only be called by an admin.
    // @param _valve New valve address
    function setValve(address _valve) external;

    // @notice Change FREEZER address.
    // @dev This method can only be called by an admin.
    // @param _freezer New freezer address
    function setFreezer(address _freezer) external;

    // @notice Buy XLA token with referal.
    // @dev Buy XLA token with referal. Only for verifiyed user. 
    // @param _token An address of token which we pay for XLA token.  
    // @param sendAmount Value which pay for XLA token.   
    // @param referal Address who get 4% of mintAmount.   
    function buyWithRef(address _token, uint256 sendAmount, address referal) external;

    // @notice Buy XLA token without referal.
    // @dev Buy XLA token without referal. Only for verifiyed user. 
    // @param _token An address of token which we pay for XLA token.  
    // @param sendAmount Value which pay for XLA token.   
    function buyWithoutRef(address _token, uint256 sendAmount) external;

    // @notice Counting the value of tokens for a mint.
    // @dev Counting the value of tokens for a mint. For all users. 
    // @param USD Value which paid for XLA token.   
    // @return The amount of XLA tokens received per amountUSD.
    function amountToSend(uint256 amountUSD) external returns(uint256);
}