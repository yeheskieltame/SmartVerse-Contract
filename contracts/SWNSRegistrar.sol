// SPDX-License-Identifier: MIT

// SmartVerse Naming Protocol - Versi 7 (Perbaikan TypeError)

pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SWNSRegistrar is ERC721, ERC721Enumerable, ERC721Burnable, Ownable {
    // --- State Variables ---
    uint256 public registrationFee;
    uint256 public renewalFee;
    mapping(uint256 => uint256) public nameExpiresAt;
    mapping(uint256 => string) private _tokenIdToName;
    mapping(uint256 => bool) private _tokenExists;
    // --- Constants ---
    uint256 public constant REGISTRATION_PERIOD = 365 days;
    uint256 public constant GRACE_PERIOD = 90 days;
    // --- Events ---

    event NameRegistered(
        string name,
        address indexed owner,
        uint256 indexed tokenId,
        uint256 expires
    );

    event NameRenewed(string name, uint256 expires);

    // --- Constructor ---

    constructor(
        address initialOwner,
        uint256 _initialRegFee,
        uint256 _initialRenewalFee
    ) ERC721("SmartVerse Name", "SW") Ownable(initialOwner) {
        registrationFee = _initialRegFee;

        renewalFee = _initialRenewalFee;
    }

    // --- Core Functions ---

    function register(string calldata name) external payable {
        require(bytes(name).length > 2, "Name: Must be at least 3 characters");

        uint256 tokenId = uint256(keccak256(abi.encodePacked(name)));

        require(_isAvailable(tokenId), "Name: Not available");

        require(
            msg.value >= registrationFee,
            "Fee: Insufficient registration fee"
        );

        if (_tokenExists[tokenId]) {
            _burn(tokenId);
        }

        uint256 expirationTime = block.timestamp + REGISTRATION_PERIOD;

        nameExpiresAt[tokenId] = expirationTime;

        _tokenIdToName[tokenId] = name;

        _safeMint(msg.sender, tokenId);

        emit NameRegistered(name, msg.sender, tokenId, expirationTime);
    }

    function renew(string calldata name) external payable {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(name)));

        require(_tokenExists[tokenId], "Name: Not found");

        require(
            block.timestamp < nameExpiresAt[tokenId] + GRACE_PERIOD,
            "Name: Grace period has ended"
        );

        require(
            ownerOf(tokenId) == msg.sender,
            "Auth: Only the owner can renew"
        );

        require(msg.value >= renewalFee, "Fee: Insufficient renewal fee");

        uint256 newExpirationTime = nameExpiresAt[tokenId] +
            REGISTRATION_PERIOD;

        nameExpiresAt[tokenId] = newExpirationTime;

        emit NameRenewed(name, newExpirationTime);
    }

    // --- View Functions ---

    function resolve(string calldata name) external view returns (address) {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(name)));

        require(block.timestamp < nameExpiresAt[tokenId], "Name: Expired");

        return ownerOf(tokenId);
    }

    function getNamesByAddress(address owner)
        external
        view
        returns (string[] memory)
    {
        uint256 balance = balanceOf(owner);

        string[] memory names = new string[](balance);

        for (uint256 i = 0; i < balance; i++) {
            uint256 tokenId = tokenOfOwnerByIndex(owner, i);

            names[i] = _tokenIdToName[tokenId];
        }

        return names;
    }

    function getExpirationTime(string calldata name)
        external
        view
        returns (uint256)
    {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(name)));

        require(_tokenExists[tokenId], "Name: Not found");

        return nameExpiresAt[tokenId];
    }

    function isAvailable(string calldata name) external view returns (bool) {
        uint256 tokenId = uint256(keccak256(abi.encodePacked(name)));

        return _isAvailable(tokenId);
    }

    // --- Internal & Override Functions ---

    function _isAvailable(uint256 tokenId) internal view returns (bool) {
        return
            !_tokenExists[tokenId] ||
            block.timestamp > nameExpiresAt[tokenId] + GRACE_PERIOD;
    }

    // FIX 2: Override _increaseBalance untuk menyelesaikan konflik pewarisan.
    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function _update(
        address to,
        uint256 tokenId,
        address auth
    ) internal override(ERC721, ERC721Enumerable) returns (address) {
        address from = _ownerOf(tokenId);

        if (from == address(0)) {
            _tokenExists[tokenId] = true;
        } else if (to == address(0)) {
            _tokenExists[tokenId] = false;
        }
        return super._update(to, tokenId, auth);
    }
    // FIX 1: Menghapus IERC165 dari daftar override.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    // --- Admin Functions ---
    function setRegistrationFee(uint256 _newFee) external onlyOwner {
        registrationFee = _newFee;
    }
    function setRenewalFee(uint256 _newFee) external onlyOwner {
        renewalFee = _newFee;
    }
    function withdraw() external onlyOwner {
        (bool success, ) = payable(owner()).call{value: address(this).balance}(
            ""
        );
        require(success, "Withdrawal failed");
    }
}
