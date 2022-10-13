// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;
/// @title IXLA
/// @author FormalCrypto

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";

/// @notice IXLA interface or XLA contract.
/// @dev IXLA interface or XLA contract.
interface IXLA is IERC20, IAccessControl{

    // @notice Mint XLA token.
    // @dev Mint XLA token. Only for MINTER_ROLE.
    // @param buyer
    // @param buyerAmount Amount which minted for buyer.
    // @param referal
    // @param referalAmount Amount which minted for referal.
    // @param defaultReferal
    // @param defaultReferalAmount Amount which minted for defaultReferal.
    function mint(address buyer, uint256 buyerAmount, address referal, uint256 referalAmount, address defaultReferal, uint256 defaultReferalAmount) external;

    // @notice Burn the XLA token as a penalty for not meeting the XLA terms
    // @dev Burn the XLA token as a penalty for not meeting the XLA terms. Only for BURNER_ROLE.
    // @param burnAddress Address from which tokens are burned
    // @param burnAmount Amount which burned from burnAddress.
    function burn(address burnAddress, uint256 burnAmount) external;
}