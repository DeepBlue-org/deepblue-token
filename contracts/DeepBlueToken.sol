// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title DeepBlueToken
 * @notice ERC-20 with owner-controlled minting, batch airdrop, and burn support.
 * @dev Deploy on Base L2 for minimal gas. Owner = deployer wallet.
 */
contract DeepBlueToken is ERC20, ERC20Burnable, Ownable {
    uint256 public constant MAX_SUPPLY = 1_000_000_000 * 1e18; // 1B tokens

    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialMint_
    ) ERC20(name_, symbol_) Ownable(msg.sender) {
        if (initialMint_ > 0) {
            require(initialMint_ <= MAX_SUPPLY, "Exceeds max supply");
            _mint(msg.sender, initialMint_);
        }
    }

    /// @notice Owner can mint tokens (for airdrops, rewards, etc.)
    /// @param to Recipient address
    /// @param amount Amount in wei (18 decimals)
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply() + amount <= MAX_SUPPLY, "Exceeds max supply");
        _mint(to, amount);
    }

    /// @notice Batch airdrop from owner's balance to multiple recipients in one tx.
    /// @param recipients Array of addresses to receive tokens
    /// @param amounts Array of amounts (must match recipients length)
    function batchAirdrop(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(recipients.length == amounts.length, "Length mismatch");
        require(recipients.length <= 200, "Too many recipients"); // gas safety

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amounts[i]);
        }
    }

    /// @notice Batch airdrop equal amounts to all recipients
    /// @param recipients Array of addresses
    /// @param amountEach Amount each address receives
    function batchAirdropEqual(
        address[] calldata recipients,
        uint256 amountEach
    ) external onlyOwner {
        require(recipients.length <= 200, "Too many recipients");

        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amountEach);
        }
    }

    /// @notice Mint directly to multiple addresses (no prior balance needed)
    /// @param recipients Array of addresses
    /// @param amounts Array of amounts
    function batchMint(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external onlyOwner {
        require(recipients.length == amounts.length, "Length mismatch");
        require(recipients.length <= 200, "Too many recipients");

        for (uint256 i = 0; i < recipients.length; i++) {
            require(totalSupply() + amounts[i] <= MAX_SUPPLY, "Exceeds max supply");
            _mint(recipients[i], amounts[i]);
        }
    }
}
