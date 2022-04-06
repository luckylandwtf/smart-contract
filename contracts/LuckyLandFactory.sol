pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/IAccessControl.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "./interface/ILuckyLandFactory.sol";
import "./interface/ILuckyLandLottery.sol";

contract LuckyLandFactory is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    address public template;
    address payable private teamAddress;
    address[] public allLotteries;

    // div is 10000
    // [4,3,2,1] => [10%, 15%, 25%, 50%]
    // [10%, 15%, 25%, 50%] => [1000,2500,5000,10000]
    uint[] public AirdropProportion;

    address Airdrop;
    uint AirdropPrice;
    uint feeRate;

    bool canAirdrop;
    
    bool public freeLinkToken;

    bytes32 keyHash;
    uint fee;
    address linkToken;
    address vrfCoordinator;

    event SetTeamAddress(address team);
    event SetFeeRate(uint feeRate);
    event SetAirdrop(uint price, bool canAirdrop);
    event SetPayLinkToken(bool free);
    event SetAirdropProportion(uint[] proportion);

    event CreateNewLottery(
        address indexed owner,
        address indexed lottery,
        address indexed nft,
        uint _nftType,
        uint _tokenId,
        uint _endTime,
        uint _unitPrice,
        uint _totalAmount
    );

    constructor(
        address _template,
        address payable _teamAddress,
        bytes32 _keyHash,
        uint _fee,
        address _linkToken,
        address _vrfCoordinator,
        address _Airdrop,
        uint[] memory _AirdropProportion,
        uint _AirdropPrice,
        uint _feeRate) {
        
        template = _template;
        teamAddress = _teamAddress;
        keyHash = _keyHash;
        fee = _fee;
        linkToken = _linkToken;
        vrfCoordinator = _vrfCoordinator;
        Airdrop = _Airdrop;
        AirdropProportion = _AirdropProportion;
        AirdropPrice = _AirdropPrice;
        feeRate = _feeRate;
        canAirdrop = true;
        freeLinkToken = true;
    }

    function createLottery(
        bytes32 _salt,
        address _nft,
        uint _nftType,
        uint _tokenId,
        uint _endTime,
        uint _unitPrice,
        uint _totalAmount) external nonReentrant {
        
        require(_totalAmount > 1,"LuckyLandFactory: amount must be greater than 1");

        ILuckyLandLottery luckyLandLottery = ILuckyLandLottery(Clones.cloneDeterministic(template, _salt));
        
        luckyLandLottery.initCreate(keyHash, fee, vrfCoordinator, linkToken, Airdrop, AirdropProportion);
        luckyLandLottery.initLottery(payable(msg.sender), _nft, _nftType, _tokenId, _endTime, _unitPrice, _totalAmount);
        address lottery = address(luckyLandLottery);
        allLotteries.push(lottery);

        // add minter
        bytes32 ROLE_MINTER = keccak256(bytes("ROLE_MINTER"));
        
        IAccessControl(Airdrop).grantRole(ROLE_MINTER, lottery);
        
        require((_nftType == 721) || (_nftType == 1155), "LuckyLandFactory: can not create");

        if (_nftType == 721) {
            IERC721(_nft).transferFrom(msg.sender, lottery, _tokenId);
        } else if (_nftType == 1155) {
            IERC1155(_nft).safeTransferFrom(msg.sender, lottery, _tokenId, 1, '0x0');
        }
        
        if (freeLinkToken) {
            IERC20(linkToken).safeTransfer(lottery, fee);
        }else{
            IERC20(linkToken).safeTransferFrom(msg.sender,lottery, fee);
        }
        
        emit CreateNewLottery(
            msg.sender,
            lottery,
            _nft,
            _nftType,
            _tokenId,
            _endTime,
            _unitPrice,
            _totalAmount);
    }

    function allLotteriesOf(uint index) external view returns (address lottery){
        return allLotteries[index];
    }

    function allLotteriesLength() external view returns (uint) {
        return allLotteries.length;
    }

    function setFeeRate(uint _feeRate) external onlyOwner {
        require(_feeRate <= 500,"LuckyLandFactory: Exceed maximum");
        feeRate = _feeRate;
        emit SetFeeRate(feeRate);
    }

    function setTeamAddress(address payable _teamAddress) external onlyOwner {
        require(_teamAddress != address(0),"LuckyLandFactory: cannot be the zero address.");
        teamAddress = _teamAddress;
        
        emit SetTeamAddress(teamAddress);
    }

    function getFeeRateAndTeam() external view
        returns (uint _feeRate, address payable _teamAddress) {
        _feeRate = feeRate;
        _teamAddress = teamAddress;
    }
    
    function payLinkToken(bool _free) external onlyOwner {
        freeLinkToken = _free;
        emit SetPayLinkToken(freeLinkToken);
    }

    function setAirdrop(uint _AirdropPrice, bool _canAirdrop) external onlyOwner {
        AirdropPrice = _AirdropPrice;
        canAirdrop = _canAirdrop;
        emit SetAirdrop(AirdropPrice, canAirdrop);
    }
    
    function setAirdropProportion(uint[] memory _proportion) external onlyOwner {
        AirdropProportion = _proportion;
        emit SetAirdropProportion(AirdropProportion);
    }
    
    function airdropRule(uint uintPrice) external view returns (bool) {
        return (uintPrice >= AirdropPrice && canAirdrop);
    }
    
    // Implement a withdraw function to avoid locking your LINK in the contract
    function withdrawLink(address token, uint256 amount) external onlyOwner {
        require(linkToken == token,"LuckyLandFactory: only withdraw Link");
        IERC20(token).safeTransfer(owner(), amount);
    }

}
