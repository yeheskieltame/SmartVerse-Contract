// SPDX-License-Identifier: MIT
// SmartVerse - Business Vault v1.1 (Perbaikan Event)
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract BusinessVault is Ownable, ReentrancyGuard {

    struct Transaction {
        uint256 id;
        uint256 timestamp;
        bool isIncome;
        string category;
        address tokenAddress;
        uint256 amount;
        address actor;
    }

    // --- State Variables ---
    uint256 public totalNativeIncome;
    uint256 public totalNativeExpense;
    mapping(address => uint256) public totalTokenIncome;
    mapping(address => uint256) public totalTokenExpense;

    Transaction[] public transactionLog;
    
    // --- Events ---
    // FIX: Menambahkan `timestamp` agar cocok dengan pemanggilan emit.
    event TransactionRecorded(
        uint256 indexed id, 
        uint256 timestamp,
        bool isIncome, 
        string category, 
        address indexed tokenAddress, 
        uint256 amount, 
        address indexed actor
    );

    constructor(address initialOwner) Ownable(initialOwner) {}

    // --- Fungsi Pemasukan ---

    function depositNative(string calldata _category) external payable {
        uint amount = msg.value;
        require(amount > 0, "Amount must be greater than zero");
        totalNativeIncome += amount;
        _logTransaction(true, _category, address(0), amount, msg.sender);
    }
    
    function depositToken(address _tokenAddress, uint256 _amount, string calldata _category) external {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        IERC20 token = IERC20(_tokenAddress);
        totalTokenIncome[_tokenAddress] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);
        _logTransaction(true, _category, _tokenAddress, _amount, msg.sender);
    }

    // --- Fungsi Pengeluaran ---

    function withdrawNative(uint256 _amount, string calldata _category) external onlyOwner nonReentrant {
        require(address(this).balance >= _amount, "Vault: Insufficient native balance");
        totalNativeExpense += _amount;
        _logTransaction(false, _category, address(0), _amount, owner());
        (bool success, ) = payable(owner()).call{value: _amount}("");
        require(success, "Vault: Native withdrawal failed");
    }
    
    function withdrawToken(address _tokenAddress, uint256 _amount, string calldata _category) external onlyOwner nonReentrant {
        require(_tokenAddress != address(0), "Token address cannot be zero");
        IERC20 token = IERC20(_tokenAddress);
        require(token.balanceOf(address(this)) >= _amount, "Vault: Insufficient token balance");
        totalTokenExpense[_tokenAddress] += _amount;
        _logTransaction(false, _category, _tokenAddress, _amount, owner());
        token.transfer(owner(), _amount);
    }

    // --- Fungsi Internal untuk Pencatatan ---
    function _logTransaction(bool _isIncome, string memory _category, address _tokenAddress, uint256 _amount, address _actor) private {
        uint txId = transactionLog.length;
        transactionLog.push(Transaction({
            id: txId,
            timestamp: block.timestamp,
            isIncome: _isIncome,
            category: _category,
            tokenAddress: _tokenAddress,
            amount: _amount,
            actor: _actor
        }));
        // Pemanggilan emit ini sekarang sudah benar dengan 7 argumen
        emit TransactionRecorded(txId, block.timestamp, _isIncome, _category, _tokenAddress, _amount, _actor);
    }

    // --- Fungsi View ---
    function getTransactionLogCount() external view returns (uint256) {
        return transactionLog.length;
    }
}