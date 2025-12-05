// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title BookToken
 * @notice ERC20 reward token for the BookLending platform
 * @dev Optimized for Arbitrum - maintains identical logic to Sepolia version
 */
contract BookToken is ERC20, Ownable {
    constructor() ERC20("Book Token", "BOOK") Ownable(msg.sender) {
        _mint(msg.sender, 1000000 * 10 ** decimals());
    }

    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}