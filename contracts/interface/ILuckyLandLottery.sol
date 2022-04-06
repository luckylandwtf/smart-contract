pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

interface ILuckyLandLottery {
    function initCreate(
        bytes32 _keyHash,
        uint _fee,
        address _vrfCoordinator,
        address _linkToken,
        address _card,
        uint[] memory _cardProportion) external;
    
    function initLottery(
        address payable _originalOwner,
        address _nft,
        uint _nftType,
        uint _id,
        uint _endTime,
        uint _unitPrice,
        uint _totalAmount) external;
}
