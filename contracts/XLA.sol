// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/// @title XLA
/// @author FormalCrypto

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

/// @notice XLA token contract.
/// @dev Designed to mint with Token Sale Machine.
contract XLA is ERC20, AccessControl{
    //  Role for mint XLA token.
    bytes32 private constant MINTER_ROLE = keccak256("MINTER_ROLE");
    //  Role for burn XLA token.
    bytes32 private constant BURNER_ROLE = keccak256("BURNER_ROLE");
    //  Max Supply. No one can mint XLA token more hen Max Supply limited.
    uint256 public maxSupply = 5 * 10 ** (12 + 18); // уточнить из таблицы по формулам.

    // @notice Create the contract to start work with it.
    // @dev Create ERC20 contract with name XLA and shortName XLA. And set DEFAULT_ADMIN_ROLE for creator.
    constructor(
    ) ERC20("XLA", "XLA") { 
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
    }

    // @notice Mint XLA token.
    // @dev Only for MINTER_ROLE (Admin grant this role for TokenSaleMachine).
    // @param buyer
    // @param buyerAmount Amount which minted for buyer.
    // @param referal
    // @param referalAmount Amount which minted for referal.
    // @param defaultReferal
    // @param defaultReferalAmount Amount which minted for defaultReferal.
    function mint(address buyer, uint256 buyerAmount, address referal, uint256 referalAmount, address defaultReferal, uint256 defaultReferalAmount) external onlyRole(MINTER_ROLE) {
        require(balanceOf(address(this)) + buyerAmount + referalAmount + defaultReferalAmount < maxSupply, "Supply limited");
        _mint(buyer, buyerAmount);
        _mint(referal, referalAmount);
        _mint(defaultReferal, defaultReferalAmount);
    }

    // @notice Burn the XLA token as a penalty for not meeting the XLA terms
    // @dev Only for BURNER_ROLE.
    // @param burnAddress Address from which tokens are burned
    // @param burnAmount Amount which burned from burnAddress.
    function burn(address burnAddress, uint256 burnAmount) external onlyRole(BURNER_ROLE){
        _burn(burnAddress, burnAmount);
    }
}