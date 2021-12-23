//SPDX-License-Identifier: lgplv3
pragma solidity ^0.8.0;

import "./MultiSigWallet.sol";

/// @title MultiSigWalletWithPermit wallet with permit -
/// @author pagefault@126.com
contract MultiSigWalletWithPermit is MultiSigWallet {
    mapping(bytes4 => bool) internal supportedInterfaces;
    bool internal ownersImmutable = true;
    bool internal initialized = false;

    modifier notImmutable() {
        require(!ownersImmutable, "immutable");
        _;
    }

    function addOwner(address owner) public override notImmutable {
        super.addOwner(owner);
    }

    function removeOwner(address owner) public override notImmutable {
        super.removeOwner(owner);
    }

    function replaceOwner(address owner, address newOwner)
        public
        override
        notImmutable
    {
        super.replaceOwner(owner, newOwner);
    }

    function changeRequirement(uint256 _required) public override notImmutable {
        super.changeRequirement(_required);
    }

    function supportsInterface(bytes4 interfaceID)
        external
        view
        returns (bool)
    {
        return supportedInterfaces[interfaceID];
    }

    function setSupportsInterface(bytes4 interfaceID, bool support)
        external
        onlyWallet
    {
        supportedInterfaces[interfaceID] = support;
    }

    /*
     * Public functions
     */
    /// @dev Contract constructor sets initial owners, required number of confirmations.
    /// @param _owners List of initial owners.
    /// @param _required Number of required confirmations.
    /// @param _immutable is owners immutable
    constructor(
        address[] memory _owners,
        uint256 _required,
        bool _immutable
    ) MultiSigWallet(_owners, _required) {
        if (_required > 0) {
            initialized = true;

            setup0(_immutable);
        }
    }

    function setup(
        address[] memory _owners,
        uint256 _required,
        bool _immutable
    ) public {
        require(!initialized, "initialized");
        initialized = true;
        super.initialize(_owners, _required);
        setup0(_immutable);
    }

    function setup0(bool _immutable) private {
        ownersImmutable = _immutable;
        supportedInterfaces[0x01ffc9a7] = true;

        uint256 chainId;
        assembly {
            chainId := chainid()
        }
        DOMAIN_SEPARATOR = keccak256(
            abi.encode(
                // keccak256(
                //     "EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)"
                // ),
                0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f,
                // keccak256(bytes("MultiSigWalletWithPermit")),
                0x911a814036e00323c4ca54d47b0a363338990ca044824eba7a28205763e6115a,
                // keccak256(bytes("1")),
                0xc89efdaa54c0f20c7adf612882df0950f5a951637e0307cdcb4c672f298b8bc6,
                chainId,
                address(this)
            )
        );
    }

    bytes32 public DOMAIN_SEPARATOR;
    bytes32 public constant PERMIT_TYPEHASH =
        0x8d14977a529be0cde9be2de41261d56c536e10c2bfb3f797a663ac4f3676d2fe;

    /*
     * executeTxWithPermits
     */
    /// @dev delegate call
    /// @param destination Transaction target address.
    /// @param value Transaction ether value.
    /// @param data Transaction data payload.
    /// @param nonce Transaction ID.
    /// @return newTransactionId Returns transaction ID.
    function executeTxWithPermits(
        address destination,
        uint256 value,
        bytes memory data,
        uint256 nonce,
        bytes32[] memory rs,
        bytes32[] memory ss,
        uint8[] memory vs
    ) public returns (uint256 newTransactionId) {
        require(isOwner[msg.sender], "not owner");
        require(rs.length == ss.length, "invalid signs");
        require(rs.length == vs.length, "invalid signs2");
        require(nonce == transactionCount, "invalid transactionId(nonce)");
        require(rs.length + 1 == required, "invalid signs3");
        require(destination != address(0), "invalid destination");

        newTransactionId = addTransaction(destination, value, data);
        confirmTransactionInner(newTransactionId, msg.sender);

        bytes32 digest = keccak256(
            abi.encodePacked(
                "\x19\x01",
                DOMAIN_SEPARATOR,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        msg.sender,
                        destination,
                        value,
                        keccak256(data),
                        nonce
                    )
                )
            )
        );

        for (uint8 i = 0; i < rs.length; ++i) {
            address owner = ecrecover(digest, vs[i], rs[i], ss[i]);
            require(owner != address(0), "0 address");
            require(isOwner[owner], "not owner");

            confirmTransactionInner(newTransactionId, owner);
        }

        if (isConfirmed(newTransactionId)) {
            executeTransactionInner(newTransactionId);
            require(transactions[newTransactionId].executed, "tx failed");
        } else {
            require(false, "confirm failed");
        }
    }

    function confirmTransactionInner(uint256 transactionId, address owner)
        private
        transactionExists(transactionId)
        notConfirmed(transactionId, owner)
    {
        confirmations[transactionId][owner] = true;
        emit Confirmation(owner, transactionId);
    }

    function executeTransactionInner(uint256 transactionId)
        private
        notExecuted(transactionId)
    {
        Transaction storage txn = transactions[transactionId];
        txn.executed = true;

        require(
            address(this).balance >= txn.value,
            "insufficient balance for call"
        );

        (bool success, bytes memory returndata) = txn.destination.call{
            value: txn.value
        }(txn.data);

        if (success) {
            emit Execution(transactionId);
        } else {
            if (returndata.length > 0) {
                assembly {
                    let returndata_size := mload(returndata)
                    revert(add(32, returndata), returndata_size)
                }
            } else {
                revert("call failed");
            }
        }
    }
}
