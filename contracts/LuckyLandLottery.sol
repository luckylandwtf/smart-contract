pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155Receiver.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./chainlink/VRFConsumerBaseUpgradable.sol";

import "./interface/ILuckyLandFactory.sol";
import "./interface/ILuckyLandCard.sol";

contract LuckyLandLottery is Context, ReentrancyGuard, VRFConsumerBaseUpgradable {
    using SafeMath for uint;
    using SafeERC20 for IERC20;

    bytes32 internal keyHash;
    uint256 internal fee;
    address internal linkToken;
    bytes32 internal linkRequestId;

    bool private hasInit;
    bool private hasInitCreate;

    address public factory;
    address internal card;
    uint[] internal cardProportion;

    address payable public  originalOwner;

    address public nft;
    uint public tokenId;
    uint public nftType;
    uint public endTime;
    uint public unitPrice;
    uint public totalAmount;
    
    bytes32 private seed;

    uint private luckyNumber; // default is 0 , but 0 is available
    address public luckyDog; // default is address(0), but address(0) is Unavailable

    mapping(address => uint[]) internal luckyIndexs;
    address[] public allLuckyDogs;
    
    mapping(address => bool) public refunded;
    bool public refundedNFT;
    mapping(address => uint) public claimAmounts;

    bool public hasDraw;

    event Create (
        uint indexed fee, 
        address indexed factory
    );

    event Init(
        address indexed originalOwner, 
        address indexed nft, 
        uint indexed id, 
        uint nftType,
        uint endTime, 
        uint unitPrice, 
        uint totalAmount
    );

    event Bet(
        address indexed sender, 
        uint amount, 
        uint[] _luckyIndexs
    );

    event Draw(
        uint indexed luckyNumber, 
        address indexed luckyDog, 
        address originalOwner, 
        uint total
    );

    event ClaimAirDropNFT (
        address indexed sender,
        uint times,
        uint[] tokenIds
    );

    event UserRefund (
        address indexed sender,
        uint times,
        uint value
    );

    event OwnerRefund (
        address indexed sender,
        address indexed nft,
        uint tokenId
    );

    event ERC721Received (
        address indexed operator,
        address indexed from,
        uint256 indexed id,
        bytes data
    );

    event ERC1155Received(
        address operator, 
        address from, 
        uint256 id, 
        uint256 value, 
        bytes data
    );

    function initCreate(
        bytes32 _keyHash,
        uint _fee,
        address _vrfCoordinator,
        address _linkToken,
        address _card,
        uint[] memory _cardProportion) external {
        VRFConsumerBaseUpgradable.vrfInitialize(
            _vrfCoordinator,
            _linkToken
        );
        require(!hasInitCreate, "initialize: Already init!");

        keyHash = _keyHash;
        fee = _fee;
        linkToken = _linkToken;
        
        card = _card;
        cardProportion = _cardProportion;

        factory = msg.sender;

        hasInitCreate = true;
        emit Create(fee, factory);
    }

    function initLottery(
        address payable _originalOwner,
        address _nft,
        uint _nftType,
        uint _id,
        uint _endTime,
        uint _unitPrice,
        uint _totalAmount) external {
        require(msg.sender == factory, 'LuckyLandLottery: FORBIDDEN');
        require(!hasInit, "initialize: Already init!");
        
        originalOwner = _originalOwner;
        nft = _nft;
        nftType = _nftType;
        tokenId = _id;
        endTime = _endTime;
        unitPrice = _unitPrice;
        totalAmount = _totalAmount;

        hasInit = true;
        emit Init(originalOwner, nft, tokenId, nftType, endTime, unitPrice, totalAmount);
    }
    
    modifier onlySuccess() {
        require(hasDraw, "LuckyLandLottery: not Success");
        _;
    }

    modifier onlyRunOff() {
        require(block.timestamp > endTime, "LuckyLandLottery: not End");
        require(!hasDraw, "LuckyLandLottery: has draw");
        _;
    }

    modifier onlyActive() {
        require(block.timestamp <= endTime, "LuckyLandLottery: has End");
        require(!hasDraw, "LuckyLandLottery: has draw");
        _;
    }

    function luckBet(uint amount) public onlyActive nonReentrant payable {
        require(amount > 0, "LuckyLandLottery: must greater than 0");
        require(amount <= availableMember(), "LuckyLandLottery: out of gauge");
        require(msg.value == amount.mul(unitPrice),"LuckyLandLottery: pay eth");

        address sender = _msgSender();
        uint[] storage _luckyIndexs = luckyIndexs[sender];
        for (uint index = 0; index < amount; index++) {
            _luckyIndexs.push(allMember());
            allLuckyDogs.push(sender);
        }

        if (availableMember() == 0) {
            linkRequestId = requestRandomness(keyHash, fee);
            hasDraw = true;
        }

        seed = keccak256(abi.encodePacked(seed, sender));

        emit Bet(sender, amount, _luckyIndexs);
    }

    function fulfillRandomness(
        bytes32 requestId,
        uint256 randomness) internal override {
            
            require(linkRequestId == requestId, "LuckyLandLottery: error request");

            luckyNumber = randomness%(totalAmount);
            luckyDog = allLuckyDogs[luckyNumber];
            
            uint total = unitPrice.mul(totalAmount);
            
            uint feeRate;
            address payable team;
            (feeRate, team) = ILuckyLandFactory(factory).getFeeRateAndTeam();
    
            uint _fee = total.mul(feeRate).div(10000);
            team.transfer(_fee);
            
            originalOwner.transfer(total.sub(_fee));
            if (nftType == 721) {
                IERC721(nft).transferFrom(address(this), luckyDog, tokenId);
            } else if (nftType == 1155) {
                IERC1155(nft).safeTransferFrom(address(this), luckyDog, tokenId, 1, '0x0');
            }
            
            seed = keccak256(abi.encodePacked(seed,randomness));

            if (ILuckyLandFactory(factory).airdropRule(unitPrice)) {
                uint level;
                uint quality;
                (level, quality) = calLevel(totalAmount.sub(1));
                ILuckyLandCard.MintParam memory mintParam;

                mintParam.creator = luckyDog;
                mintParam.quality = quality;
                mintParam.extra = level;
                
                ILuckyLandCard(card).mint(mintParam);
            }

            emit Draw(luckyNumber, luckyDog, originalOwner, total);
    }

    function availableMember() public view returns (uint) {
        return totalAmount.sub(allMember());
    }

    function allMember() public view returns (uint) {
        return allLuckyDogs.length;
    }

    // Number of bets
    function luckyTimesOf(address user) public view returns (uint) {
        return luckyIndexs[user].length;
    }

    // user bet number
    function indexOfLuckyBy(address user, uint index) external view returns (uint) {
        uint[] memory indexArray = luckyIndexs[user];
        return indexArray[index];
    }

    // End and not Completed
    function claimAirDropNFT() public onlySuccess nonReentrant {

        require(ILuckyLandFactory(factory).airdropRule(unitPrice),"LuckyLandLottery: Non compliance with airdrop rules!" );

        address sender = _msgSender();
        uint times = luckyTimesOf(sender);
        require(times > 0, "LuckyLandLottery: not bet");
        uint haveClaim = claimAmounts[sender];

        require(times > haveClaim, "LuckyLandLottery: has claimed");
        
        uint thisClaim = times.sub(haveClaim);
        if (thisClaim >= 20) {
            thisClaim = 20;
        }

        require(times > haveClaim, "LuckyLandLottery: has claimed");
        uint[] memory tokenIds = new uint[](times);
        uint[] memory indexArray = luckyIndexs[sender];
        for (uint index = haveClaim; index < haveClaim.add(thisClaim); index++) {

            uint level;
            uint quality;
            (level, quality) = calLevel(indexArray[index]);

            ILuckyLandCard.MintParam memory mintParam;
            mintParam.creator = luckyDog;
            mintParam.quality = quality;
            mintParam.extra = level;

            uint _tokenId = ILuckyLandCard(card).mint(mintParam);
            tokenIds[index] = _tokenId;
        }
        claimAmounts[sender] = claimAmounts[sender].add(thisClaim);

        emit ClaimAirDropNFT(sender, times, tokenIds);
    }

    function refundAssets() public onlyRunOff nonReentrant {
        address sender = _msgSender();
        require(!refunded[sender], "LuckyLandLottery: has withdraw");
        uint times = luckyTimesOf(sender);
        require(times > 0, "LuckyLandLottery: not bet");
        uint value = times.mul(unitPrice);
        payable(sender).transfer(value);
        refunded[sender] = true;
        
        emit UserRefund(sender, times, value);
    }

    function refundOriginalNFT() external onlyRunOff nonReentrant {
        address sender = _msgSender();
        require(sender == originalOwner, "LuckyLandLottery: not owner of nft");
        if (nftType == 721) {
            IERC721(nft).transferFrom(address(this), sender, tokenId); 
        } else if (nftType == 1155) {
            IERC1155(nft).safeTransferFrom(address(this), sender, tokenId, 1, '0x0');
        }

        IERC20(linkToken).safeTransfer(factory, fee);
        refundedNFT = true;
        emit OwnerRefund(sender, nft, tokenId);
    }
    
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external returns (bytes4) {
        
        emit ERC721Received(operator, from, id, data);
        return bytes4(keccak256("onERC721Received(address,address,uint256,bytes)"));
    }

    function onERC1155Received(address operator, address from, uint256 id, uint256 value, bytes calldata data) external returns (bytes4) {
        
        emit ERC1155Received(operator, from, id, value, data);
        return bytes4(keccak256("onERC1155Received(address,address,uint256,uint256,bytes)"));
    }

    function calLevel(uint betIndex) internal view returns(uint level, uint quality) {
        uint selfSeed = uint(keccak256(abi.encodePacked(seed, _msgSender(), betIndex)));
        uint seedBase = 10000;
        quality = selfSeed%seedBase;
        uint maxLevel = cardProportion.length;
        for (uint index = 0; index < maxLevel; index++) {
            if (quality <= seedBase.mul(cardProportion[index]).div(seedBase)) {
                level = maxLevel.sub(index);
                break;
            }
        }
    }

    receive() payable external {}
    
}
