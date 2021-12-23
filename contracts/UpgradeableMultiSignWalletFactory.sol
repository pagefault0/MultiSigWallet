//SPDX-License-Identifier: lgplv3
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "./MultiSigV1.sol";

contract UpgradeableMultiSignWalletFactory {
    event UpgradeableMultiSignWalletDeployed(
        address indexed admin,
        address indexed proxy,
        address indexed impl
    );

    function create(
        address[] memory _owners,
        uint256 _required,
        bool _immutable,
        address _impl
    ) public returns (address wallet) {
        MultiSigWalletWithPermit proxyAdmin = new MultiSigWalletWithPermit{
            salt: keccak256(
                abi.encodePacked(_owners, _required, msg.sender, _immutable)
            )
        }(_owners, _required, true);

        bytes32 newsalt = keccak256(
            abi.encodePacked(_owners, _required, msg.sender)
        );

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{
            salt: newsalt
        }(_impl, address(proxyAdmin), "");

        setup(_owners, _required, _immutable, address(proxy));

        wallet = address(proxy);

        emit UpgradeableMultiSignWalletDeployed(
            address(proxyAdmin),
            address(proxy),
            _impl
        );
    }

    function setup(
        address[] memory _owners,
        uint256 _required,
        bool _immutable,
        address proxy
    ) internal {
        MultiSigWalletWithPermit walletImpl = (
            MultiSigWalletWithPermit(payable(proxy))
        );
        walletImpl.setup(_owners, _required, _immutable);
    }
}
