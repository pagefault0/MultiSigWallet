//SPDX-License-Identifier: lgplv3
pragma solidity ^0.8.0;

import "./MultiSigWallet.sol";

contract ERC721TokenReceiver {
    function onERC721Received(
        address _operator,
        address _from,
        uint256 _tokenId,
        bytes memory _data
    ) external returns (bytes4) {
        return ERC721TokenReceiver.onERC721Received.selector;
    }
}
