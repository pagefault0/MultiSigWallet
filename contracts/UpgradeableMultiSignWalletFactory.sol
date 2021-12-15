//SPDX-License-Identifier: lgplv3
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.2/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "https://github.com/pagefault0/MultiSigWallet/blob/master/contracts/MultiSigWalletWithPermit.sol";
import "https://github.com/pagefault0/MultiSigWallet/blob/master/contracts/Factory.sol";
import "https://github.com/pagefault0/MultiSigWallet/blob/master/contracts/MultiSigWallet.sol";

contract UpgradeableMultiSignWalletFactory is Factory {
    function create(address[] memory _owners, uint256 _required)
        public
        returns (address wallet)
    {
        address[] memory initOwner = new address[](1);
        initOwner[0] = address(this);

        MultiSigWalletWithPermit proxyAdmin = new MultiSigWalletWithPermit{
            salt: keccak256(
                abi.encodePacked(_owners, _required, msg.sender, this)
            )
        }(initOwner, 1);

        bytes32 newsalt = keccak256(
            abi.encodePacked(_owners, _required, msg.sender)
        );

        MultiSigWalletWithPermit impl = new MultiSigWalletWithPermit{
            salt: newsalt
        }(new address[](0), 0);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{
            salt: newsalt
        }(address(impl), address(proxyAdmin), "");
        (MultiSigWallet(payable(proxy))).initialize(_owners, _required);

        register(wallet);
    }
}
