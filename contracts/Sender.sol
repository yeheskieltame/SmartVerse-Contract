// SPDX-License-Identifier: MIT
// Versi Perbaikan untuk Sender.sol - Fix SafeERC20
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

interface IBurnableToken is IERC20 {
    function burn(uint256 amount) external;
}

contract Sender {
    // FIX: Terapkan SafeERC20 ke kedua interface, IERC20 dan IBurnableToken.
    using SafeERC20 for IERC20;
    using SafeERC20 for IBurnableToken;

    IBurnableToken public immutable token;
    
    event FundsBridged(
        address indexed from, 
        address indexed destination, 
        uint256 amount, 
        uint256 destinationChainId
    );

    constructor(address _tokenAddress) {
        token = IBurnableToken(_tokenAddress);
    }

    function bridgeFunds(address destination, uint256 amount, uint256 destinationChainId) external {
        // 1. Tarik token dari pengguna ke kontrak ini.
        // Panggilan ini sekarang akan berhasil.
        token.safeTransferFrom(msg.sender, address(this), amount);
        
        // 2. Bakar token yang sekarang dimiliki oleh kontrak ini.
        token.burn(amount);
        
        // 3. Pancarkan event sebagai sinyal.
        emit FundsBridged(msg.sender, destination, amount, destinationChainId);
    }
}