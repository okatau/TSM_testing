// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title GlassesFactory
/// @author FormalCrypto

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Glass.sol";
import "./GlassesValve.sol";

/// @notice Implements wallet which should create and administrate Glass contract and GlassesValve.
/// @dev Designed to XLA revenue share system.
contract GlassesFactory {

    // Struct for create glass with border and owner. 
    struct glass{
        uint256 border;
        address owner;
    }
    // Tokens which can be accepted as payment under the glass contract and send by GlassesValve contract.
    address[] public acceptedTokens;
    // Glasses which created and doesn't fill.
    address[] public glasses;
    // Valve addresses.
    address[] public valves;
    // Owner addres for admin functions.
    address public owner;

    event GlassAddressLog(address _newGlass);
    event GlassesValveAddressLog(address _newGlassesValve);

    modifier onlyOwner(){
        require(owner == msg.sender, "You are not owner!");
        _;
    }

    /// @notice Create the contract to get started with it.
    /// @dev The creator is set by the owner.
    constructor(){
        owner = msg.sender;
    }

    /// @notice Delete glass with k number.
    /// @param k Delete glass with k number. 
    function delGlass(uint k) internal {
        for(uint i = k; i < glasses.length-1; i++){
            glasses[i] = glasses[i+1];      
        }
        glasses.pop();
    }

    /// @notice Delete glass which call tihs method.
    /// @dev Glass destoyed when filled and withdrawed all funds.
    function destroyGlass() external {
        for (uint i = 0; i < glasses.length; i++){
            if (msg.sender == glasses[i])
                delGlass(i);
        }
    }

    /** @notice Create new Glass.
    *   @dev After creating a "glass", 
    *        its address can be viewed by the returned number (valves[i]).
    *        The creator can withdraw getted funds.
    *   @param _glass Params for new Glass. 
    *   @return New Glass index. 
    */
    function makeGlass(glass calldata _glass) external returns(uint256){
        Glass newGlass = new Glass(payable(_glass.owner), _glass.border, acceptedTokens);
        glasses.push(address(newGlass));
        emit GlassAddressLog(address(newGlass));
        return glasses.length;
    }

    /// @notice Create new Glasses.
    /// @dev Several glasses are created.
    /// @param _glasses Params for new Glasses. 
    /// @return Range limit for new Glasses index. 
    function makeGlasses(glass[] calldata _glasses) external returns(uint256, uint256){
        for (uint i = 0; i < _glasses.length; i++)
            this.makeGlass(_glasses[i]);
        return (glasses.length - _glasses.length, glasses.length);
    }

    /** @notice Create new Valve.
    *   @dev After creating a "Valve", 
    *        its address can be viewed by the returned number (valves[i]).
    *        The creator can add filling cups to the configuration after creation
    *   @param _owner Owner Params for new Valves. 
    *   @return New Valve index. 
    */
    function makeValve(address _owner) external returns(uint256) {
        GlassesValve valve = new GlassesValve(_owner, acceptedTokens);
        valves.push(address(valve));
        // GlassesValve(valves[valves.length]).setAcceptedTokens(acceptedTokens);
        emit GlassesValveAddressLog(address(valve));
        return (valves.length);
    }

    /// @notice Create new Valves.
    /// @param _owners Params for new Valves. 
    /// @return Made GlassesValve indexes range. 
    function makeValves(address[] calldata _owners) external returns(uint256, uint256){
        for (uint i = 0; i < _owners.length; i++)
            this.makeValve(_owners[i]);
        return (valves.length - _owners.length, valves.length);
    }

    /// @notice Set accepted tokens for Valve and Glasses.
    /// @dev Set accepted tokens for Valve and Glasses.
    /// @param _tokens Accepted tokens array. 
    function setAcceptedTokens(address[] calldata _tokens) external onlyOwner{
        require(_tokens.length <= 3, "Amount of token should be less or equal 3");
        for (uint j = 0; j < glasses.length; j++){
            Glass(glasses[j]).setAcceptedTokens(_tokens);
        }
        for (uint j = 0; j < valves.length; j++){
            GlassesValve(valves[j]).setAcceptedTokens(_tokens);
        }
    }

    /// @notice Revoke owner.
    /// @dev Transferring the owner role 
    ///      and all its functions to a 'newOwner' address
    /// @param newOwner New owner address for new Valve. 
    function revokeOwner(address newOwner) onlyOwner() external{
        owner = newOwner;
    }
}