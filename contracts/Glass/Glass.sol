// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Glasss
/// @author FormalCrypto

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./GlassesFactory.sol";

/// @notice Implements wallet which should get $ fix amount
/// @dev Designed to XLA revenue share system.
contract Glass {
    // Factory address to set Accepted tokens
    address public factory;
    // The amount of the contract in dollars
    uint256 public border;
    // Amount transferred from GlassesValve
    uint256 public fullness;
    // Tokens which can be accepted as payment under the contract
    address [] public acceptedTokens;
    // Number of withdrawn tokens ($)
    uint256 public withdrawAmount;
    // An address that an accepted token can withdraw
    address payable public owner;

    /// @dev The contract is created by the factory.
    /// @param _owner The address which can withdraw funds.
    /// @param _border How many tokens owner should be get.
    /// @param _acceptedTokens Token addresses which we get and withdraw in glass contract.
    constructor(address payable _owner, uint256 _border, address[] memory _acceptedTokens){
        factory = msg.sender;
        border = _border;
        fullness = 0;
        owner = _owner;
        setAcceptedTokens(_acceptedTokens);
    }

    modifier onlyFactory(){
        require(msg.sender == factory, "You are not owner");
        _;
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not owner");
        _;
    }

    /// @notice Set Accepted tokens.
    /// @dev Only Factory can set accepted tokens.
    /// @param token array of accepted tokens.
    function setAcceptedTokens(address[] memory token) onlyFactory public {
        require(token.length <= 5, "Accepted token length should be less or equal 5");
        for (uint i = acceptedTokens.length; i > 0; i-- )
            acceptedTokens.pop();
        for(uint i = 0; i < token.length; i++)
            acceptedTokens.push(token[i]);
    }

    /// @notice Count balance of accepted tokens.
    /// @dev The loop sums up all of the avaiableTokens balances, 
    ///      taking into account decimals.
    function balance() external view returns(uint256){
        uint256 _balance = 0; 
        for (uint i = 0; i < acceptedTokens.length; i++){
            _balance += IERC20(acceptedTokens[i]).balanceOf(address(this)); 
        }
        return _balance;
    }

    /// @notice Checking the received token.
    /// @param addr Address of token.
    /// @return "True" if the address is among the received tokens.
    function inAcceptedTokens(address addr) public view returns (bool){
        for (uint i = 0; i < acceptedTokens.length; i++){
            if (acceptedTokens[i] == addr)
                return true;
        }  
        return false;
    }

    /// @notice Witdraw funds.
    /// @dev OnlyOwner function to withdraw getted ERC20 funds.
    function Withdraw() onlyOwner external payable{
        for (uint i = 0; i < acceptedTokens.length; i++){
            address _token = acceptedTokens[i]; 
            if (_token != address(0)){
                withdrawAmount += IERC20(_token).balanceOf(address(this));
                IERC20(_token).transfer(owner, IERC20(_token).balanceOf(address(this)));
            }
        }
        if (fullness == border){
            GlassesFactory(factory).destroyGlass();
            selfdestruct(payable(address(this)));
        }
    }

    /// @notice Get Token.
    /// @dev GlassesValve call this method when send funds to fill Glass.
    /// @param addr An address of getting token.
    /// @param amount Getted token amount.
    function getToken(address addr, uint256 amount) external{
        require(inAcceptedTokens(addr), "Contract doesn't accept this token");
        IERC20(addr).transferFrom(msg.sender, address(this), amount);
        fullness += amount;
    }
}