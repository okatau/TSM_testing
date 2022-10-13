// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title Valve
/// @author FormalCrypto

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/// @notice Valve contract for revenue share XLA system. 
/// @dev Designed to distrubute ERC20 Token.
contract Valve is AccessControl{

    // Amount of splited Tokens.
    uint256 public totalSplited;          
    // Minimum split percent (0.0001%).
    uint256 public decimals = 10**6;
    // Percent which get stream address.
    mapping (address => uint256) public percent;    
    // Addresses which get tokens in Split.
    address[] public streams;
    // Avaiable Tokens which should be splited. 
    address[] public avaiableTokens; 
    // Param for reEntrancyStop modifiyer. avaiableTokens.length should be less or equal 3.
    bool private lock = false;

    // Information about stream.
    struct Stream{
        address streamAddress;
        uint256 percent;
    }

    modifier reEntrancyStop(){
        require(!lock, "Reentrancy Stop!");
        lock = true;
        _;
        lock = false;
    } 

    /// @dev Create contract and setup DEFAULT_ADMIN_ROLE for creaor. 
    constructor () {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }


    /// @notice Clear all available token addresses. 
    /// @dev function is internal. 
    function clearAvaiableTokens() internal returns(bool){
        for(; avaiableTokens.length > 0;)   
            avaiableTokens.pop();
        require(avaiableTokens.length == 0, "Something went wrong in clear streams process");
        return avaiableTokens.length == 0;
    }

    /// @notice Add available token address, which would be sent.
    /// @dev Only for user with DEFAULT_ADMIN_ROLE 
    /// @param _token Added address of avaiable token
    function addAvaiableToken(address _token) onlyRole(DEFAULT_ADMIN_ROLE) external {
        require(avaiableTokens.length <= 3, "Accepted tokens should be less or equal 3");
        avaiableTokens.push(_token);
    }

    /// @notice Update available token addresses, which would be sent. 
    /// @dev Only for user with DEFAULT_ADMIN_ROLE
    ///      Clear previous list 'avaiableTokens' and set new.
    /// @param _tokens Update addresses of avaiable tokens.
    function updateAvaiableTokens(address[] calldata _tokens) onlyRole(DEFAULT_ADMIN_ROLE) external {
        require(_tokens.length <= 3, "Accepted tokens should be less or equal 3");
        clearAvaiableTokens();
        for (uint i = 0; i < _tokens.length; i++)
            avaiableTokens.push(_tokens[i]);
    }

    /// @notice Clear stream addresses with percent values. 
    /// @dev Function is internal. 
    function clearStreams() internal returns(bool){
        for (uint i = 0 ; i < streams.length  ; i++) 
            percent[streams[i]] = 0;
        for (; streams.length > 0; )         
            streams.pop();
        return (streams.length == 0);
    }

    /// @notice Update streams, which get ERC20 tokens in split. 
    /// @dev Only for user with DEFAULT_ADMIN_ROLE.
    ///      Clear previous config and set new configuration.
    /// @param _streams Array with Stream struct (address, percent) to send.
    function updateStreams(Stream[] memory _streams) external onlyRole(DEFAULT_ADMIN_ROLE) {
        bool success = clearStreams();
        require(success, "Error in clear Streams");
        uint256 sum = 0;
        for (uint256 i = 0; i < _streams.length; i++){
            streams.push(_streams[i].streamAddress);   
            percent[_streams[i].streamAddress] = _streams[i].percent;
            sum += _streams[i].percent;
        }
        require(streams.length > 0, "Won't update streams");
        require(sum == decimals, "Sum of percent should be equal 100%");
    }

    /// @notice Count balance of accepted tokens.
    /// @dev The loop sums up all of the avaiableTokens balances, 
    ///      taking into account decimals.
    function balance() external view returns(uint256){
        uint256 _balance = 0; 
        for (uint i = 0; i < avaiableTokens.length; i++){
            _balance += IERC20(avaiableTokens[i]).balanceOf(address(this)) * 10**( 18 - ERC20(avaiableTokens[i]).decimals() ); 
        }
        return _balance;
    }

    /// @notice Distribution of all ERC20 tokens on the balance in accordance with the shares of streams. 
    /// @dev Everyone can call this function. 
    function Split() external {
        require(this.balance() > 0, "Can't split zero balance");
        for (uint j = 0; j < avaiableTokens.length; j++){
            uint256 totalBalance = IERC20(avaiableTokens[j]).balanceOf(address(this));
            if (totalBalance > 0){
                for(uint i = 0; i < streams.length; i++)
                {
                    address _stream = streams[i];
                    uint256 amount = totalBalance * percent[_stream] / decimals;
                    IERC20(avaiableTokens[j]).transfer(_stream, amount);
                    totalSplited += amount;
                }
            }
        }
    }
}