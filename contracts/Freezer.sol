// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Freezer
/// @author FormalCrypto

import "./Interface/IXLA.sol";
import "./TokenSaleMachine.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @notice Freezer is the contract 
///         which get XLA token from TokenSaleMachine sale if refferal non verified.  
///         Stores tokens until refferal verified and withdraw funds.   
/// @dev Designed to hold ERC20 XLA token and interact with TokenSaleMachine contract.
contract Freezer {
    
    // Address XLA token
    address public xlaTokenAddress;  
    // List of users who have can claim XLA token
    mapping (address => uint256) public claimList;
    // Balance in XLA tokens
    uint256 private balance; 
    // Token Sale Machine address
    TokenSaleMachine private TSM;
    // Admin address
    address private admin;
    // Bool variable for reEntrancyStop
    bool private lock = false;

    modifier onlyClaimListUser() {
        require(claimList[msg.sender] > 0, "You haven't token for claim");
        _;
    }

    modifier reEntrancyStop(){
        require(!lock, "Stop reEntrancy");
        lock = true;
        _;
        lock = false;
    }

    modifier isTSM(){
        require(msg.sender == address(TSM), "You're not TSM");
        _;
    } 

    modifier isAdmin(){
        require(admin == msg.sender, "You're not Admin");
        _;
    } 

    /// @notice Create the contract to get started with it.
    /// @dev Sets XLA token, Token Sale Machine and admin.
    /// @param _token The address of the XLA.
    /// @param _tsm The address of the TSM.
    constructor(address _token, address _tsm){
        xlaTokenAddress = _token;
        TSM = TokenSaleMachine(_tsm);
        admin = msg.sender;
    }

    /// @notice Changing TSM address for flexible update Token Sale Machine contract.
    /// @dev TSM can addClaimer. Also Freezer call TSM to check is 'verified' user.
    /// @param newTSM New address for Token Sale Machine.
    function changeTSM(address newTSM) external isAdmin{
        TSM = TokenSaleMachine(newTSM);
    }

    /// @notice Add user address and his balance of XLA token which may be claimed after verification in Token Sale Machine.
    /// @dev This method can only call TSM.
    /// @param claimer It's referral address, which wasn't be verified but use in referal program.
    function addClaimer(address claimer) external isTSM reEntrancyStop {
        require(IERC20(xlaTokenAddress).balanceOf(address(this)) - balance > 0, "User has no tokens for Claim");
        uint256 newBalance = IERC20(xlaTokenAddress).balanceOf(address(this)) - balance;
        balance = IERC20(xlaTokenAddress).balanceOf(address(this));
        claimList[claimer] += newBalance;
    }

    /// @notice Withdraw XLA Token from Freezer contract.
    /// @dev This method can only call verifiyed user with non zero value for claim.
    function withdraw() external onlyClaimListUser reEntrancyStop {
        require(TSM.verified(msg.sender), "you are not verified");
        uint256 amount = claimList[msg.sender];
        claimList[msg.sender] = 0;
        IERC20(xlaTokenAddress).transfer(msg.sender, amount);
    }
}