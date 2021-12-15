//SPDX-License-Identifier: lgplv3
pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/release-v4.2/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "./MultiSigWalletWithPermit.sol";

// is Factory
contract UpgradeableMultiSignWalletFactory {
    event UpgradeableMultiSignWalletDeployed(
        address indexed admin,
        address indexed proxy,
        address indexed impl
    );

    function create(address[] memory _owners, uint256 _required)
        public
        returns (address wallet)
    {
        MultiSigWalletWithPermit proxyAdmin = new MultiSigWalletWithPermit{
            salt: keccak256(
                abi.encodePacked(_owners, _required, msg.sender, this)
            )
        }(_owners, _required);

        bytes32 newsalt = keccak256(
            abi.encodePacked(_owners, _required, msg.sender)
        );

        MultiSigWalletWithPermit impl = new MultiSigWalletWithPermit{
            salt: newsalt
        }(new address[](0), 0);

        TransparentUpgradeableProxy proxy = new TransparentUpgradeableProxy{
            salt: newsalt
        }(address(impl), address(proxyAdmin), "");

        MultiSigWallet walletImpl = (MultiSigWallet(payable(proxy)));
        walletImpl.initialize(_owners, _required);

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
