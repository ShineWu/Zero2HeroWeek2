// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract RewardToken {
    // 帐号余额
    mapping(address => uint256) private _balances;
    // 帐号授权给其它地址的授权余额
    mapping(address => mapping(address => uint256)) private _allowances;
    // 合约拥有者
    address private _owner;

    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals = 18;

    constructor(string memory name_, string memory symbol_) {
        _name = name_;
        _symbol = symbol_;
        _owner = msg.sender;
    }

    // 代币名字
    function name() public view returns(string memory) {
        return _name;
    }

    // 代币符号
    function symbol() public view returns(string memory) {
        return _symbol;
    }

    // 代币精度
    function decimals() public view returns(uint8) {
        return _decimals;
    }

    // 交易事件
    event Transfer(address indexed from, address indexed to, uint256 value);
    // 授权事件
    event Approval(address indexed owner, address indexed spender, uint256 value);
    // 转移所有权
    event OwnershipTransferred(address indexed from, address indexed to);

    // 判定是不是拥有者
    modifier onlyOwner() {
        require(msg.sender == _owner, "Ownable: caller is not the owner");
        _;
    }

    // 总代币数量
    function totalSupply() public view returns(uint256) {
        return _totalSupply;
    }

    // 查询帐号余额
    function balanceOf(address account) public view returns(uint256) {
        return _balances[account];
    }

    // owner 授权给 spender 的授权余额
    function allowance(address owner_, address spender) public view returns(uint256) {
        return _allowances[owner_][spender];
    }

    // owner 授权给 spender 使用 amount 个代币
    function _approve(address owner_, address spender, uint256 amount) internal {
        require (owner_ != address(0), "BEP20: approve owner the zero address");
        require (spender != address(0), "BEP20: approve spender the zero address");
        _allowances[owner_][spender] = amount;
        emit Approval(owner_, spender, amount);
    }

    // 消耗掉 owner 授权给 spender 的 amount 个代币
    function _spendAllowance(address owner_, address spender, uint256 amount) internal {
        uint256 curAllowance = allowance(owner_, spender);
        if (curAllowance == type(uint256).max) {
            return;
        }

        require(curAllowance >= amount, "BEP20: Insufficient allowance");
        _approve(owner_, spender, curAllowance - amount);
    }

    // 授权给 spender 地址 amount 个代币
    function approve(address spender, uint256 amount) public returns(bool) {
        address owner_ = msg.sender;
        _approve(owner_, spender, amount);
        return true;
    }

    // 增加授权给 spender 的余额
    function increaseAllowance(address spender, uint256 addValue) internal returns(bool) {
        address owner_ = msg.sender;
        uint256 curAllowance = allowance(owner_, spender);
        _approve(owner_, spender, curAllowance + addValue);
        return true;
    }

    // 减少授权给 spender 的余额
    function decreaseAllowance(address spender, uint256 subValue) internal returns(bool) {
        address owner_ = msg.sender;
        uint256 curAllowance = allowance(owner_, spender);
        require(curAllowance >= subValue, "BEP20: decreased allownace below zero");
        _approve(owner_, spender, curAllowance - subValue);
        return true;
    }

    //
    function _transfer(address from, address to, uint256 amount) internal {
        require (from != address(0), "BEP20: approve from the zero address");
        require (to != address(0), "BEP20: approve to the zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "BEP20: transfer amount exceeds balance");

        _balances[from] -= amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    // 给 to 地址发送 amount 个代币
    function transfer(address to, uint256 amount) public returns(bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    // 从 from 地址发送 amount 个代币到 to 地址
    function transferFrom(address from, address to, uint256 amount) public returns(bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    // 查询当前合约拥有者
    function owner() public view returns(address) {
        return _owner;
    }

    // 转移所有者给 newOnwer
    function _transferOwnership(address newOwner) internal {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }

    // 转移所有者给 newOnwer
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    // 生成 amount 个代币给 account 地址
    function _mint(address account, uint256 amount) internal {
        require(account != address(0), "Ownable: mint to the zero address");

        _totalSupply += amount;
        _balances[account] += amount;

        emit Transfer(address(0), account, amount);
    }

    // 生成 amount 个代币给 account 地址
    function mint(address account, uint256 amount) public onlyOwner {
        _mint(account, amount);
    }

    // 销毁 account 地址 amount 个代币
    function _burn(address account, uint256 amount) internal {
        require(account != address(0), "BEP20: account is the zero address");

        uint256 curBalance = _balances[account];
        require(curBalance >= amount, "BEP20: burn amount exceeds balance");

        _balances[account] -= amount;
        _totalSupply -= amount;

        emit Transfer(account, address(0), amount);
    }

    // 销毁 amount 个代币
    function burn(uint256 amount) public {
        _burn(msg.sender, amount);
    }

    //  从 account 地址销毁 amount 个代币
    function burnFrom(address account, uint256 amount) public {
        address spender = msg.sender;
        _spendAllowance(account, spender, amount);
        _burn(account, amount);
    }
}
