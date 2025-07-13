// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MockIDRT is ERC20, ERC20Burnable, Ownable {
    constructor(address initialOwner) ERC20("Mock Digital Rupiah", "mIDRT") Ownable(initialOwner) {
        // Cetak 1 Miliar token awal untuk pemilik kontrak
        _mint(initialOwner, 1_000_000_000 * 10**decimals());
    }

    // Fungsi untuk mencetak token baru. Hanya bisa dipanggil oleh pemilik.
    // Nantinya, kita akan berikan hak ini ke kontrak Receiver.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }
}