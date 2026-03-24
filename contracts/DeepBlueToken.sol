// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title DeepBlueBase Token ($DBB)
/// @notice ERC-20 with 1% transfer fee, fee-exempt whitelist, batch airdrop, mint/burn
contract DeepBlueToken {
    string public constant name = "DeepBlueBase";
    string public constant symbol = "DBB";
    uint8 public constant decimals = 18;

    uint256 public totalSupply;
    address public owner;

    // Fee config
    uint256 public feeRate = 100; // basis points (1% = 100)
    uint256 public constant MAX_FEE_RATE = 500; // 5% cap
    uint256 public constant FEE_DENOMINATOR = 10000;
    address public treasury;

    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    mapping(address => bool) public feeExempt;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event FeeRateUpdated(uint256 oldRate, uint256 newRate);
    event FeeExemptUpdated(address indexed account, bool exempt);
    event OwnershipTransferred(address indexed oldOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    /// @param _totalSupply Total supply in wei (e.g. 10_000_000e18 for 10M)
    /// @param _owner Owner address (receives all tokens, controls admin functions)
    /// @param _treasury Treasury address for fee collection
    constructor(uint256 _totalSupply, address _owner, address _treasury) {
        require(_owner != address(0), "Zero owner");
        require(_treasury != address(0), "Zero treasury");
        owner = _owner;
        treasury = _treasury;
        totalSupply = _totalSupply;
        balanceOf[_owner] = _totalSupply;

        // Owner and treasury are fee-exempt by default
        feeExempt[_owner] = true;
        feeExempt[_treasury] = true;

        emit Transfer(address(0), _owner, _totalSupply);
    }

    function transfer(address to, uint256 value) external returns (bool) {
        return _transfer(msg.sender, to, value);
    }

    function approve(address spender, uint256 value) external returns (bool) {
        allowance[msg.sender][spender] = value;
        emit Approval(msg.sender, spender, value);
        return true;
    }

    function transferFrom(address from, address to, uint256 value) external returns (bool) {
        require(allowance[from][msg.sender] >= value, "Insufficient allowance");
        allowance[from][msg.sender] -= value;
        return _transfer(from, to, value);
    }

    /// @dev Core transfer with fee logic
    function _transfer(address from, address to, uint256 value) internal returns (bool) {
        require(balanceOf[from] >= value, "Insufficient balance");
        require(to != address(0), "Transfer to zero");

        uint256 fee = 0;
        if (!feeExempt[from] && !feeExempt[to] && feeRate > 0) {
            fee = (value * feeRate) / FEE_DENOMINATOR;
        }

        uint256 sendAmount = value - fee;
        balanceOf[from] -= value;
        balanceOf[to] += sendAmount;
        emit Transfer(from, to, sendAmount);

        if (fee > 0) {
            balanceOf[treasury] += fee;
            emit Transfer(from, treasury, fee);
        }

        return true;
    }

    // ── Admin functions ──

    /// @notice Batch airdrop a fixed amount to multiple recipients (fee-free)
    function batchAirdrop(address[] calldata recipients, uint256 amount) external onlyOwner {
        uint256 total = amount * recipients.length;
        require(balanceOf[owner] >= total, "Insufficient balance for airdrop");
        for (uint256 i = 0; i < recipients.length; i++) {
            balanceOf[owner] -= amount;
            balanceOf[recipients[i]] += amount;
            emit Transfer(owner, recipients[i], amount);
        }
    }

    /// @notice Mint new tokens to an address
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "Mint to zero");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }

    /// @notice Burn tokens from owner's balance
    function burn(uint256 amount) external onlyOwner {
        require(balanceOf[owner] >= amount, "Insufficient balance to burn");
        balanceOf[owner] -= amount;
        totalSupply -= amount;
        emit Transfer(owner, address(0), amount);
    }

    /// @notice Update fee rate (capped at MAX_FEE_RATE)
    function setFeeRate(uint256 _feeRate) external onlyOwner {
        require(_feeRate <= MAX_FEE_RATE, "Exceeds max fee rate");
        uint256 old = feeRate;
        feeRate = _feeRate;
        emit FeeRateUpdated(old, _feeRate);
    }

    /// @notice Set fee-exempt status for an address (e.g. LP pool, team)
    function setFeeExempt(address account, bool exempt) external onlyOwner {
        feeExempt[account] = exempt;
        emit FeeExemptUpdated(account, exempt);
    }

    /// @notice Update treasury address
    function setTreasury(address _treasury) external onlyOwner {
        require(_treasury != address(0), "Zero treasury");
        treasury = _treasury;
    }

    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero owner");
        address old = owner;
        owner = newOwner;
        emit OwnershipTransferred(old, newOwner);
    }
}
