pragma solidity ^0.8.0;
// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@chainlink/contracts/src/v0.8/interfaces/LinkTokenInterface.sol";
import "@chainlink/contracts/src/v0.8/VRFRequestIDBase.sol";

abstract contract VRFConsumerBaseUpgradable is VRFRequestIDBase {
    using SafeMath for uint256;

    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal virtual;
    
    /**
    * @dev In order to keep backwards compatibility we have kept the user
    * seed field around. We remove the use of it because given that the blockhash
    * enters later, it overrides whatever randomness the used seed provides.
    * Given that it adds no security, and can easily lead to misunderstandings,
    * we have removed it from usage and can now provide a simpler API.
    */
    uint256 private constant USER_SEED_PLACEHOLDER = 0;

    function requestRandomness(bytes32 _keyHash, uint256 _fee) internal returns (bytes32 requestId) {
        LINK.transferAndCall(vrfCoordinator, _fee, abi.encode(_keyHash, USER_SEED_PLACEHOLDER));
        uint256 vRFSeed  = makeVRFInputSeed(_keyHash, USER_SEED_PLACEHOLDER, address(this), nonces[_keyHash]);
        nonces[_keyHash] = nonces[_keyHash].add(1);
        return makeRequestId(_keyHash, vRFSeed);
    }

    // removed immutable keyword <--
    LinkTokenInterface internal LINK;
    
    // removed immutable keyword <--
    address private vrfCoordinator;

    mapping(bytes32 /* keyHash */ => uint256 /* nonce */) private nonces;
    
    // Flag of initialize data
    bool private initialized;

    // replaced constructor with initializer <--
    function vrfInitialize(address _vrfCoordinator, address _link) public {
        require(!initialized, "vrfInitialize: Already initialized!");
        vrfCoordinator = _vrfCoordinator;
        LINK = LinkTokenInterface(_link);
        initialized = true;
    }

    function rawFulfillRandomness(bytes32 requestId, uint256 randomness) external {
        require(msg.sender == vrfCoordinator, "Only VRFCoordinator can fulfill");
        fulfillRandomness(requestId, randomness);
    }
}