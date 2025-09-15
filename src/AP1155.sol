// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.30;

import { ERC1155 } from "solady/tokens/ERC1155.sol";
import { Base64 } from "solady/utils/Base64.sol";
import { LibString } from "solady/utils/LibString.sol";
import { ReentrancyGuardTransient } from "solady/utils/ReentrancyGuardTransient.sol";

contract AP1155 is ERC1155, ReentrancyGuardTransient {

    uint256 constant PLATFORM_FEE = 8e13;

    address immutable feeRecipient;
    address immutable creator;
    uint256 immutable creatorFee;
    uint256 immutable referralFee;

    struct TokenMetadata {
        string name;
        string symbol;
        string description;
        string image;
        string external_link;
    }

    TokenMetadata public tokenMetadata;

    mapping(uint256 id => string uri) public _tokenURIs;
    mapping(uint256 id => uint256 deadline) public _mintCloseDate;

    event TokenAdded(uint256 id);
    event TokenMinted(uint256 amount, uint256 id);
    event TokensMinted(uint256[] amounts, uint256[] ids);
    event PermanentURI(string tokenURI, uint256 id);

    error MintFeeFailed();
    error NotCreator();
    error CreatorFeeFailed();
    error ReferralFeeFailed();
    error TokenNotConfigured();
    error TokenAlreadyConfigured();
    error MintClosed();
    error BatchLengthWrong();
    error ZeroAmount();

    constructor(
        string memory _metadata,
        address _feeRecipient,
        address _creator,
        uint256 _creatorFee,
        uint256 _referralFee,
        string memory _name,
        string memory _symbol,
        string memory _description,
        string memory _image,
        string memory _external_link
    ) {
        _tokenURIs[1] = string(
            abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(_metadata)))
        );

        feeRecipient = _feeRecipient;
        creator = _creator;
        creatorFee = _creatorFee;
        referralFee = _referralFee;

        tokenMetadata = TokenMetadata({
            name: _name,
            symbol: _symbol,
            description: _description,
            image: _image,
            external_link: _external_link
        });
        _mint(_creator, 1, 1, "");
    }

    function _mintChecks(uint256 id, address referrer) internal {
        require(bytes(_tokenURIs[id]).length != 0, TokenNotConfigured());

        uint256 expiration = _mintCloseDate[id];

        if (expiration != 0 && block.timestamp > expiration) {
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

    function _mintChecks(uint256[] calldata ids, address referrer) internal {
        uint256 lengths = ids.length;

        for (uint256 i = 0; i < lengths; i++) {
            require(bytes(_tokenURIs[ids[i]]).length != 0, TokenNotConfigured());

            uint256 expiration = _mintCloseDate[ids[i]];

            if (expiration != 0 && block.timestamp > expiration) {
                revert MintClosed();
            }
        }

        (bool mintFeeOk,) = feeRecipient.call{ value: PLATFORM_FEE * lengths }("");
        (bool creatorFeeOk,) = creator.call{ value: creatorFee * lengths }("");

        if (referrer != address(0)) {
            (bool referralFeeOk,) = referrer.call{ value: referralFee * lengths }("");
            require(referralFeeOk, ReferralFeeFailed());
        } else {
            (bool defaultReferral,) = feeRecipient.call{ value: referralFee * lengths }("");
            require(defaultReferral, ReferralFeeFailed());
        }

        require(mintFeeOk, MintFeeFailed());
        require(creatorFeeOk, CreatorFeeFailed());
    }

    function configureToken(uint256 id, string memory tokenURI, uint256 expiration) external {
        require(msg.sender == creator, NotCreator());
        require(bytes(_tokenURIs[id]).length == 0, TokenAlreadyConfigured());
        _mintCloseDate[id] = expiration;
        _tokenURIs[id] = tokenURI;
        _mint(creator, id, 1, "");

        emit TokenAdded({ id: id });
        emit PermanentURI({ tokenURI: tokenURI, id: id });
    }

    function contractURI() public view returns (string memory) {
        return string.concat(
            '{"name":"',
            LibString.escapeJSON(tokenMetadata.name),
            '",',
            '"description":"',
            LibString.escapeJSON(tokenMetadata.description),
            '",',
            '"image":"',
            LibString.escapeJSON(tokenMetadata.image),
            '",',
            '"external_link":"',
            LibString.escapeJSON(tokenMetadata.external_link),
            '"}'
        );
    }

    function uri(
        uint256 id
    ) public view override returns (string memory) {
        return _tokenURIs[id];
    }

    function mint(
        uint256 id,
        uint16 amount,
        address to,
        address referrer
    ) external payable nonReentrant {
        require(amount > 0, ZeroAmount());
        _mintChecks(id, referrer);
        _mint(to, id, amount, "");
        emit TokenMinted({ id: id, amount: amount });
    }

    function batchMint(
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address to,
        address referrer
    ) external payable nonReentrant {
        require(ids.length > 0, ZeroAmount());
        require(ids.length == amounts.length, BatchLengthWrong());
        _mintChecks(ids, referrer);
        _batchMint(to, ids, amounts, "");
        emit TokensMinted({ amounts: amounts, ids: ids });
    }

}
