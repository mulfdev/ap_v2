// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.30;

import { AP1155 } from "./AP1155.sol";
import { Ownable } from "solady/auth/Ownable.sol";

/// @title APFactory
/// @author mulf
/// @notice Factory contract for deploying new AP1155 collection contracts.
/// @dev This contract allows users to create new AP1155 collections with specified parameters.
/// It inherits from Ownable for access control on fee recipient updates.
contract APFactory is Ownable {

    /// @notice Address that receives fees from collections created by this factory.
    /// @dev Can be updated by the contract owner.
    address public feeRecipient;

    /// @notice Emitted when a new collection is deployed.
    /// @param newCollection The address of the newly deployed AP1155 contract.
    event CollectionCreated(address newCollection);

    /// @notice Constructor to initialize the factory.
    /// @dev Sets the initial fee recipient to the deployer and initializes ownership.
    constructor() {
        feeRecipient = 0xcDad9f233dAFC49E81b3aC1Abef7C8ef8334986A;
        _initializeOwner(0xcDad9f233dAFC49E81b3aC1Abef7C8ef8334986A);
    }

    /// @notice Updates the fee recipient address.
    /// @dev Only callable by the contract owner.
    /// @param newFeeRecipient The new address to receive fees.
    function updateFeeRecipient(
        address newFeeRecipient
    ) external onlyOwner {
        feeRecipient = newFeeRecipient;
    }

    /// @notice Deploys a new AP1155 collection contract.
    /// @dev Creates a new AP1155 instance with the provided parameters and emits a
    /// CollectionCreated event.
    /// @param metadata Base64-encoded JSON metadata for the collection.
    /// @param creatorFee Fee percentage for the creator (in basis points).
    /// @param referralFee Fee percentage for referrals (in basis points).
    /// @param name Name of the collection.
    /// @param symbol Symbol of the collection.
    /// @param description Description of the collection.
    /// @param image Image URL for the collection.
    /// @param external_link External link for the collection.
    /// @return The address of the newly deployed AP1155 contract.
    function deployNew(
        string memory metadata,
        uint256 creatorFee,
        uint256 referralFee,
        string memory name,
        string memory symbol,
        string memory description,
        string memory image,
        string memory external_link
    ) external returns (address) {
        address newCollection = address(
            new AP1155(
                metadata,
                feeRecipient,
                msg.sender,
                creatorFee,
                referralFee,
                name,
                symbol,
                description,
                image,
                external_link
            )
        );
        emit CollectionCreated({ newCollection: newCollection });
        return newCollection;
    }

}
