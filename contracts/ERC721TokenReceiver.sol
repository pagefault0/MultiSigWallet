//SPDX-License-Identifier: lgplv3
pragma solidity ^0.8.0;

contract ERC721TokenReceiver {
    function onERC721Received(
        address,
        address,
        uint256,
        bytes memory
    ) external pure returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}
