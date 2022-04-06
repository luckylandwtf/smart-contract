pragma solidity ^ 0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interface/ILuckyLandCard.sol";

contract LuckyLandCard is Ownable, AccessControl, ILuckyLandCard, ERC721Enumerable, ReentrancyGuard {
    using Strings for uint;

    // 0xaeaef46186eb59f884e36929b6d682a6ae35e1e43d8f05f058dcefb92b601461
    bytes32 constant ROLE_MINTER = keccak256(bytes(ROLE_MINTER_STR));
   
    string constant ROLE_MINTER_STR = "ROLE_MINTER";
    
    bytes32 constant ROLE_MINTER_ADMIN = keccak256(bytes(ROLE_MINTER_ADMIN_STR));

    string constant ROLE_MINTER_ADMIN_STR = "ROLE_MINTER_ADMIN";

    uint256 private _tokenId = 0;
    
    mapping(uint => MintParam) private tokenParam;

    string private baseURI;

    event SetMinterAdmin(
        bytes32 role,
        bytes32 adminRole,
        address admin
    );

    event RevokeMinterAdmin(
        bytes32 role,
        bytes32 adminRole
    );

    event DefaultAdminRole(
        address defaultAdmin
    );
    
    event URIPrefix(string indexed baseURI);

    constructor() ERC721("Card", "Card.LuckyLand") {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        baseURI = "https://api.luckyland.wtf/card/";
    }
    
    function setMinterAdmin(address factory) external onlyOwner {
        _setRoleAdmin(ROLE_MINTER, ROLE_MINTER_ADMIN);
        _setupRole(ROLE_MINTER_ADMIN, factory);
        emit SetMinterAdmin(ROLE_MINTER, ROLE_MINTER_ADMIN, factory);
    }

    function revokeMinterAdmin() external onlyOwner {
        _setRoleAdmin(ROLE_MINTER, DEFAULT_ADMIN_ROLE);
        emit RevokeMinterAdmin(ROLE_MINTER, DEFAULT_ADMIN_ROLE);
    }
    
    function setDefaultAdminRole(address defaultAdmin) external onlyOwner {
        _setupRole(DEFAULT_ADMIN_ROLE, defaultAdmin);
        
        emit DefaultAdminRole(defaultAdmin);
    }

    function supportsInterface(bytes4 interfaceId) public view virtual override(AccessControl, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function mint(MintParam calldata mintParam) external override nonReentrant returns(uint){
        require(hasRole(ROLE_MINTER, msg.sender), "LuckyLandCard: Caller is not a minter");
        _tokenId++;
        _mint(mintParam.creator, _tokenId);
        tokenParam[_tokenId] = mintParam;
        return _tokenId;
    }

    function getTokenParam(uint tokenId) external view override returns(MintParam memory mintParam) {
        require(_exists(tokenId), "LuckyLandCard: Param query for nonexistent token");
        mintParam = tokenParam[tokenId];
    }

    function setURIPrefix(string memory baseURI_) external onlyOwner {
        baseURI = baseURI_;
        emit URIPrefix(baseURI);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_exists(tokenId), "LuckyLandCard: URI query for nonexistent token");
        string memory baseURI_ = _baseURI();
        return string(abi.encodePacked(baseURI_, tokenId.toString()));
    }
}