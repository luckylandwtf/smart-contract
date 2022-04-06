pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

interface ILuckyLandFactory {
    function getFeeRateAndTeam()
        external
        view
        returns (uint _feeRate, address payable _teamAddress);
    
    function airdropRule(uint unitPrice) external view returns (bool);
}
