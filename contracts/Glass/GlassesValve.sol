// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title GlassesValve
/// @author FormalCrypto

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Glass.sol";

/// @notice Implements GalssesValve which should send Tokens to Glass contract.
/// @dev
contract GlassesValve {
    // Tokens which can be accepted as payment under the contract
    address[] public acceptedTokens;
    // User who can add Glasses in queue
    address public owner;
    // Factory address
    address public factory;
    // Info struct for Glass  
    struct GlassData {
        uint256 border;
        uint256 fullness;
        address addr;
    }
    // Glasses which should be fill
    GlassData[] public glasses;

    /// @notice Help function to choose min between two numbers
    /// @dev Help function to choose min between two numbers
    /// @param a uint256
    /// @param b uint256 
    function min(uint256 a, uint256 b) public pure returns(uint256){
        if (a < b) 
            return a;
        else 
            return b;
    }

    /// @notice Create the contract to get started with it.
    /// @dev The contract is created by the factory.
    /// @param _owner The address which can add glass into queue.
    /// @param _acceptedTokens Token addresses which we can send into Glass contract for fill.
    constructor(address _owner, address[] memory _acceptedTokens) {
        factory = msg.sender;
        owner = _owner;
        setAcceptedTokens(_acceptedTokens);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "You are not owner!");
        _;
    }

    modifier onlyFactory(){
        require(msg.sender == factory, "You are not factory!");
        _;
    }

    /// @notice Delete glass with zero number.
    /// @dev Delete glass with zero number.
    function delFirstGlass() internal {
        for(uint i = 0; i < glasses.length-1; i++)
            glasses[i] = glasses[i+1];      
        glasses.pop();
    }

    /// @notice Set Accepted tokens.
    /// @dev Set Accepted tokens. Only Factory can set accepted tokens.
    /// @param _acceptedTokens Array of accepted tokens.
    function setAcceptedTokens(address [] memory _acceptedTokens) public onlyFactory{
        for (uint i = acceptedTokens.length; i > 0; i -- )
            acceptedTokens.pop();
        for (uint i = 0; i < _acceptedTokens.length; i++)
            acceptedTokens.push(_acceptedTokens[i]);
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

    /// @notice Consistently fills glasses.
    /// @dev If one of glasses filled in process 
    ///      It's deleteded from queue and Valve start fill next Glass. 
    function fillGlass() external {
        require(glasses.length > 0, "No glasses");
        uint256 b = this.balance();
        if ( b > glasses[0].border - glasses[0].fullness){
            for (uint i = 0; i < acceptedTokens.length; i++){
                uint256 am = min(IERC20(acceptedTokens[i]).balanceOf(address(this)), glasses[0].border - glasses[0].fullness);
                IERC20(acceptedTokens[i]).approve(glasses[0].addr, am);
                Glass(glasses[0].addr).getToken(acceptedTokens[i], am);
                glasses[0].fullness += am;
                if (glasses[0].fullness == glasses[0].border)
                    i = acceptedTokens.length;
            }
            delFirstGlass();
            if (glasses.length > 0)
                this.fillGlass();
        }
        else{
            for (uint i = 0; i < acceptedTokens.length; i++){
                uint256 am = min(IERC20(acceptedTokens[i]).balanceOf(address(this)), glasses[0].border - glasses[0].fullness);
                IERC20(acceptedTokens[i]).approve(glasses[0].addr, am);
                Glass(glasses[0].addr).getToken(acceptedTokens[i], am);
                glasses[0].fullness += am;
            }
            if (glasses[0].fullness == glasses[0].border)
                delFirstGlass();
        }
    }

    /// @notice Push glasses in queue
    /// @dev No one can't delete Glass, only fill and then glass self destroy.
    /// @param _glasses Glass addresses to add in queue. 
    function addGlasses(address[] calldata _glasses) external onlyOwner{
        for (uint i = 0; i < _glasses.length; i++){
            glasses.push(
               GlassData(
                    Glass(_glasses[i]).border(), 
                    Glass(_glasses[i]).fullness(),
                    _glasses[i]
                )
            );
        }
    }

    /// @notice Amount of glasses info.
    /// @dev Public view function. 
    /// @return Glasses length. 
    function amountOfGlasses() public view returns(uint256){
        return glasses.length;
    }

    /// @notice Withdraw ETH.
    /// @dev OnlyOwner function to withdraw getted randomly ETH funds.
    function withdrawETH() external payable onlyOwner{
        payable(msg.sender).transfer(address(this).balance);
    }
}