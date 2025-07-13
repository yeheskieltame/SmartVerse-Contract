// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Mengimpor kontrak MockIDRT untuk bisa memanggil fungsi mint
import "./MockIDRT.sol";

contract Receiver {
    MockIDRT public immutable token;
    address public relayer; // Alamat yang berperan sebagai "kurir pesan"

    event FundsReceived(address indexed to, uint256 amount);

    constructor(address _tokenAddress, address _relayerAddress) {
        token = MockIDRT(_tokenAddress);
        relayer = _relayerAddress;
    }

    /**
     * @notice Mengeksekusi pesan dari relayer untuk mencetak token.
     * @dev Hanya bisa dipanggil oleh alamat relayer yang sudah ditetapkan.
     * @param destination Alamat penerima akhir.
     * @param amount Jumlah token yang akan dicetak.
     */
    function executeBridge(address destination, uint256 amount) external {
        // Keamanan: Hanya relayer yang bisa memicu fungsi ini
        require(msg.sender == relayer, "Caller is not the authorized relayer");
        
        // 1. Berikan hak `mint` ke kontrak ini sementara
        // Catatan: Pemilik kontrak token harus mentransfer ownership ke kontrak ini
        token.mint(destination, amount);
        
        // 2. Pancarkan event
        emit FundsReceived(destination, amount);
    }

    // Fungsi admin untuk mengubah alamat relayer jika diperlukan
    function setRelayer(address _newRelayer) external {
        // Asumsi hanya pemilik awal (deployer) yang bisa mengubah ini.
        // Untuk produksi, gunakan Ownable.
        require(msg.sender == relayer, "Only current relayer can set a new one");
        relayer = _newRelayer;
    }
}