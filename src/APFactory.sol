// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.30;

import { AP1155 } from "./AP1155.sol";
import { Ownable } from "solady/auth/Ownable.sol";

contract APFactory is Ownable {

    address public feeRecipient;

    constructor() {
        feeRecipient = msg.sender;
        _initializeOwner(msg.sender);
    }

    function updateFeeRecipient(
        address newFeeRecipient
    ) external onlyOwner {
        feeRecipient = newFeeRecipient;
    }

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
        return address(new AP1155(metadata, feeRecipient, msg.sender, creatorFee, referralFee, name, symbol, description, image, external_link));
    }

}
