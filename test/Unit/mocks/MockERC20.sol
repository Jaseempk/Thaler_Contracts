// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/**
 * @title MockERC20
 * @notice A simplified ERC20 token for testing purposes
 * @dev Implements basic ERC20 functionality with additional mint function for testing
 */
contract MockERC20 {
    string public name;
    string public symbol;
    uint8 public decimals;
    uint256 public totalSupply;

    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    /**
     * @notice Constructor to create a new MockERC20 token
     * @param _name Name of the token
     * @param _symbol Symbol of the token
     * @param _decimals Number of decimals for the token
     */
    constructor(string memory _name, string memory _symbol, uint8 _decimals) {
        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
     * @notice Get the balance of an account
     * @param account The address to query the balance of
     * @return The token balance
     */
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    /**
     * @notice Get the allowance granted by an owner to a spender
     * @param owner The address that owns the tokens
     * @param spender The address that can spend the tokens
     * @return The remaining allowance
     */
    function allowance(address owner, address spender) external view returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @notice Approve a spender to spend tokens on behalf of the caller
     * @param spender The address that will be allowed to spend tokens
     * @param amount The amount of tokens that can be spent
     * @return success Always returns true
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        _allowances[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    /**
     * @notice Transfer tokens from the caller to a recipient
     * @param recipient The address to receive the tokens
     * @param amount The amount of tokens to transfer
     * @return success Always returns true
     */
    function transfer(address recipient, uint256 amount) external returns (bool) {
        require(_balances[msg.sender] >= amount, "ERC20: transfer amount exceeds balance");
        
        _balances[msg.sender] -= amount;
        _balances[recipient] += amount;
        
        emit Transfer(msg.sender, recipient, amount);
        return true;
    }

    /**
     * @notice Transfer tokens from one address to another
     * @param sender The address to transfer tokens from
     * @param recipient The address to transfer tokens to
     * @param amount The amount of tokens to transfer
     * @return success Always returns true
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool) {
        require(_balances[sender] >= amount, "ERC20: transfer amount exceeds balance");
        require(_allowances[sender][msg.sender] >= amount, "ERC20: insufficient allowance");
        
        _balances[sender] -= amount;
        _balances[recipient] += amount;
        _allowances[sender][msg.sender] -= amount;
        
        emit Transfer(sender, recipient, amount);
        return true;
    }

    /**
     * @notice Mint new tokens (for testing purposes only)
     * @param account The address to mint tokens to
     * @param amount The amount of tokens to mint
     */
    function mint(address account, uint256 amount) external {
        _balances[account] += amount;
        totalSupply += amount;
        
        emit Transfer(address(0), account, amount);
    }

    /**
     * @notice Burn tokens (for testing purposes only)
     * @param account The address to burn tokens from
     * @param amount The amount of tokens to burn
     */
    function burn(address account, uint256 amount) external {
        require(_balances[account] >= amount, "ERC20: burn amount exceeds balance");
        
        _balances[account] -= amount;
        totalSupply -= amount;
        
        emit Transfer(account, address(0), amount);
    }
}
