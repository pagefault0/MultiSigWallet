//SPDX-License-Identifier: lgplv3
pragma solidity ^0.8.0;

import "./ERC721TokenReceiver.sol";
import "./MultiSigWalletWithPermit.sol";

/// @title MultiSigV1
/// @author pagefault@126.com
contract MultiSigV1 is MultiSigWalletWithPermit, ERC721TokenReceiver {
    constructor(address[] memory _owners, uint256 _required)
        MultiSigWalletWithPermit(_owners, _required)
    {}

    function eipFeatures() pure public returns(uint[2] memory fs){
        fs = [uint(165),uint(721)];
    }

    function version() pure public returns(uint){
        return 1;
    }
}
