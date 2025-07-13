// SPDX-License-Identifier: MIT
// SmartVerse - Business Factory v1.0
pragma solidity ^0.8.20;

// Kita akan mengimpor kontrak BusinessVault yang akan kita buat selanjutnya.
// Pastikan file BusinessVault.sol berada di direktori yang sama.
import "./BusinessVault.sol";

/**
 * @title BusinessFactory
 * @author SmartVerse Team
 * @notice Kontrak ini berfungsi sebagai pabrik untuk membuat dan melacak
 * BusinessVault baru untuk para UMKM di ekosistem SmartVerse.
 */
contract BusinessFactory {

    // Menyimpan catatan: dari alamat wallet pengguna -> ke alamat kontrak BusinessVault miliknya.
    // Ini memastikan setiap pengguna hanya bisa memiliki satu vault.
    mapping(address => address) public userToVault;
    
    // Event yang dipancarkan setiap kali vault baru berhasil dibuat.
    // Frontend akan mendengarkan event ini untuk mendapatkan alamat vault baru.
    event VaultCreated(address indexed user, address indexed vaultAddress);

    /**
     * @notice Membuat sebuah BusinessVault baru untuk pengguna (msg.sender).
     * @dev Akan gagal jika pengguna sudah memiliki vault.
     * Setelah berhasil, kontrak ini memancarkan event VaultCreated.
     */
    function createBusinessVault() external {
        // Pengecekan keamanan: Pastikan pengguna belum pernah membuat vault sebelumnya.
        require(userToVault[msg.sender] == address(0), "Factory: Vault already exists for this user");

        // "Menciptakan" instance baru dari kontrak BusinessVault.
        // `msg.sender` (pemanggil fungsi ini) secara otomatis akan menjadi pemilik dari vault baru tersebut.
        BusinessVault newVault = new BusinessVault(msg.sender);

        // Menyimpan alamat kontrak vault yang baru dibuat ke dalam catatan kita.
        userToVault[msg.sender] = address(newVault);

        // Memancarkan event untuk memberitahu dunia luar (terutama frontend)
        // bahwa sebuah vault baru telah dibuat beserta alamatnya.
        emit VaultCreated(msg.sender, address(newVault));
    }
}