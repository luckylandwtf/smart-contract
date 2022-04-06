pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

interface ILuckyLandCard {
    
    struct MintParam {
        address creator;
        uint quality;
        uint extra;
    }
    
    function getTokenParam(uint tokenId) external view returns(MintParam memory mintParam);
    
    function mint(MintParam calldata mintParam) external returns(uint);
}
