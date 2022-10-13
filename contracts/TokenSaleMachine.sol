// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title TokenSaleMachine
/// @author FormalCrypto

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "./Interface/IXLA.sol";
import "./Interface/IFreezer.sol";
import "./Interface/IValve.sol";
import "./Verifiyer.sol";

/// @notice Implements selling process for XLA token 
///         Bounding curve model
///         The XLA price is dynamic and is calculated as 
///         {price = alpha + k * totalSupply}
/// @dev Designed to work with Revenue Share XLA system
contract TokenSaleMachine is Verifiyer{ 

    // Bounding curve param k
    uint256 public k = 34500000; 
    // Bounding curve param alpha (0.1)
    uint256 public alpha = 10**17; 
    // Interface to call XLA token contract
    IXLA public XLA;
    // Interface to call Freezer contract
    IFreezer private FREEZER;
    // Interface to call Valve contract
    IValve private VALVE;
    /// Param for reEntrancyStop modifiyer 
    bool private lock = false;
    // Address which use when someone buy token without referal 
    address private defaultRef;
    // Address that receives 20% on every XLA sale  
    address private teamAddress;

    // event MintedAmount(uint256 amount, uint256 refAmount, uint256 teamAddressAmount);

    modifier reEntrancyStop(){
        require(!lock, "Stop reEntrancy");
        lock = true;
        _;
        lock = false;
    }

    /// @param _xla XLA token address.
    /// @param _valve Valve Address. First contract in XLA Revenue Share system. 
    /// @param _defaultRef Default Referal address for buyer without them referal address.
    /// @param _team Address which get 20% from XLA sell.
    constructor(address _xla, address _valve, address _defaultRef, address _team) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        XLA = IXLA(_xla);
        VALVE = IValve(payable(_valve));
        defaultRef = _defaultRef;
        teamAddress = _team;
    }

    /// @notice Change VALVE address. 
    ///         Valve is the first element in the XLA's revenue sharing system. 
    ///         Funds are distributed according to valve configuration.
    /// @dev This method can only be called by an admin.
    /// @param _valve New valve address
    function changeValve(address _valve) external onlyRole(DEFAULT_ADMIN_ROLE){
        VALVE = IValve(payable(_valve));
    }

    /// @notice Change teamAddress. 
    ///         teamAddress is the address which get 20% token every XLA sale. 
    /// @dev This method can only be called by an admin. 
    /// @param _teamAddress New Team address
    function changeTeamAddress(address _teamAddress) external onlyRole(DEFAULT_ADMIN_ROLE){
        teamAddress = payable(_teamAddress);
    }

    /// @notice Change defaultRef address.
    ///         'defaultRef' is the address which get 4% from XLA sell 
    ///         if user call function 'mintWithoutRef(...)'
    /// @dev This method can only be called by an admin.
    /// @param _defaultRef New default referal address.
    function changeDefaultRef(address _defaultRef) external onlyRole(DEFAULT_ADMIN_ROLE){
        defaultRef = payable(_defaultRef);
    }

    /// @notice Change FREEZER address.  
    ///         Freezer is the contract which get XLA if refferal non verified.  
    ///         And stores tokens until refferal verified and withdraw funds.   
    /// @dev This method can only be called by an admin.
    /// @param _freezer New freezer address
    function changeFreezer(address _freezer) external onlyRole(DEFAULT_ADMIN_ROLE){
        FREEZER = IFreezer(payable(_freezer));
    }

    /// @notice Internal function to mint token. 
    /// @dev Function to call 'mint' function from XLA contract. 
    /// @param buyer Wallet which get amount value of XLA token.  
    /// @param referal Wallet which get 4% from amount.
    /// @param mintAmount Value which counted in buy functions.
    function mintWithRef(address buyer, address referal, uint256 mintAmount) internal{
        XLA.mint(buyer, mintAmount, referal, mintAmount / 25, teamAddress, mintAmount / 5);
    }

    /// @notice Buy XLA token with referal.
    ///         Verified user can call this method  to send tokens from 'verifiyed Tokens' and get XLA token. 
    ///         'referal address' get 4% from getted XLA value.
    /// @dev Only for verifiyed user. 
    /// @param _token An address of token which we pay for XLA token.  
    /// @param sendAmount Value which pay for XLA token.   
    /// @param referal Address who get 4% of mintAmount.   
    function buyWithRef(address _token, uint256 sendAmount, address referal) public reEntrancyStop onlyVerifiedToken(_token) {
        require(verified[msg.sender], "You're not verified"); 
        require(referal != msg.sender || referal == defaultRef, "You can't list yourself as a referral");
        bool success = ERC20(_token).transferFrom(msg.sender, address(VALVE), sendAmount);
        require(success, "Tranfer was wrong");
        uint256 sendAmountWithDecimals = sendAmount * 10**( 18 - ERC20(_token).decimals() );
        if (verified[referal])
            mintWithRef(msg.sender, referal, amountToSend(sendAmountWithDecimals));
        else
        {
            mintWithRef(msg.sender, address(FREEZER), amountToSend(sendAmountWithDecimals));
            FREEZER.addClaimer(referal);
        }
    }

    /// @notice Buy XLA token without referal.
    ///         Verified user can call this method to send tokens from 'verifiyed Tokens' and get XLA token. 
    ///         'default referal address' get 4% from getted XLA value.
    /// @dev Only for verifiyed user. 
    ///      Buy XLA token without referal. Only for verifiyed user. 
    /// @param _token An address of token which we pay for XLA token.  
    /// @param sendAmount Value which pay for XLA token.   
    function buyWithoutRef(address _token, uint256 sendAmount) external onlyVerifiedToken(_token){
        buyWithRef(_token, sendAmount, defaultRef);
    }

    /// @notice Counting the value of tokens which will mint,
    ///         if referal send one of 'verifiyed Tokens' with value = 'amountUSD'.
    /// @dev Calculation is carried out according to the formula 
    ///      {price = alpha + k * totalSupply}.
    /// @param amountUSD Value which paid for XLA token.   
    /// @return The amount of XLA tokens received per amountUSD.
    function amountToSend(uint256 amountUSD) public view returns(uint256){
        uint256 totalSupply = XLA.totalSupply();
        return (Math.sqrt( amountUSD * 2 * k + (totalSupply * k + 10**18 * alpha)**2 / 10**36) - (k * totalSupply + 10**18 * alpha) / 10**18 ) * 10**18 / k;
    } 
}