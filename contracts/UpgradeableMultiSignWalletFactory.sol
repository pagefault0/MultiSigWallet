//SPDX-License-Identifier: lgplv3
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.2/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "./MultiSigV1.sol";

// is Factory
contract UpgradeableMultiSignWalletFactory {
    event UpgradeableMultiSignWalletDeployed(
        address indexed admin,
        address indexed proxy,
        address indexed impl
    );

    function create(address[] memory _owners, uint256 _required,
    bool _immutable)
        public
        returns (address wallet)
    {
        MultiSigWalletWithPermit proxyAdmin = new MultiSigWalletWithPermit{
            salt: keccak256(
                abi.encodePacked(_owners, _required, msg.sender, this)
            )
        }(_owners, _required, _immutable);

        bytes32 newsalt = keccak256(
            abi.encodePacked(_owners, _required, msg.sender)
        );

        MultiSigV1 impl = new MultiSigV1{salt: newsalt}(_owners, _required, _immutable);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{
            salt: newsalt
        }(address(impl), address(proxyAdmin), "");

        MultiSigWalletWithPermit walletImpl = (MultiSigWalletWithPermit(payable(proxy)));
        walletImpl.setup(_owners, _required, _immutable);

        wallet = address(proxy);
        // register(wallet);
        // register(proxyAdmin);

        emit UpgradeableMultiSignWalletDeployed(
            address(proxyAdmin),
            address(proxy),
            address(impl)
        );
    }
}
