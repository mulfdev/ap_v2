// SPDX-License-Identifier: Apache-2.0
pragma solidity 0.8.30;

import { ERC1155 } from "solady/tokens/ERC1155.sol";
import { Base64 } from "solady/utils/Base64.sol";

contract AP1155 is ERC1155 {

    uint256 constant PLATFORM_FEE = 8e13;

    address immutable feeRecipient;
    address immutable creator;
    uint256 immutable creatorFee;
    uint256 immutable referralFee;

    mapping(uint256 id => string uri) private _tokenURIs;
    mapping(uint256 id => uint256 deadline) private _mintCloseDate;

    event TokenMinted(uint256 id, address minter);

    error MintFeeFailed();
    error NotCreator();
    error CreatorFeeFailed();
    error ReferralFeeFailed();
    error TokenNotConfigured();
    error MintClosed();

    constructor(
        string memory _metadata,
        address _feeRecipient,
        address _creator,
        uint256 _creatorFee
    ) {
        _tokenURIs[1] = string(
            abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(_metadata)))
        );

        feeRecipient = _feeRecipient;
        creator = _creator;
        creatorFee = _creatorFee;
        _mint(_creator, 1, 1, "");
    }

    function _mintChecks(uint256 id, address referrer) internal {
        require(bytes(_tokenURIs[id]).length != 0, TokenNotConfigured());

        uint256 expiration = _mintCloseDate[id];

        if (expiration != 0 && expiration > block.timestamp) {
            revert MintClosed();
        }

        (bool mintFeeOk,) = feeRecipient.call{ value: PLATFORM_FEE }("");
        (bool creatorFeeOk,) = creator.call{ value: creatorFee }("");

        if (referrer != address(0)) {
            (bool referralFeeOk,) = referrer.call{ value: referralFee }("");
            require(referralFeeOk, ReferralFeeFailed());
        }

        require(mintFeeOk, MintFeeFailed());
        require(creatorFeeOk, CreatorFeeFailed());
    }

    function configureToken(uint256 id, string memory tokenURI, uint256 expiration) external {
        require(msg.sender == creator, NotCreator());
        _mintCloseDate[id] = expiration;
        _tokenURIs[id] = tokenURI;
        _mint(creator, id, 1, "");
    }

    function uri(
        uint256 id
    ) public view override returns (string memory) {
        return _tokenURIs[id];
    }

    function mint(uint256 id, uint16 amount, address to, address referrer) public payable {
        _mintChecks(id, referrer);
        _mint(to, id, amount, "");

        emit TokenMinted({ id: id, minter: msg.sender });
    }

}
