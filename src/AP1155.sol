// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.30;

import { ERC1155 } from "solady/tokens/ERC1155.sol";
import { Base64 } from "solady/utils/Base64.sol";
import { LibString } from "solady/utils/LibString.sol";
import { ReentrancyGuardTransient } from "solady/utils/ReentrancyGuardTransient.sol";

/**
 * @title AP1155 - Artist Program ERC1155 Token Contract
 * @notice Multi-token NFT contract with creator monetization features
 * @author mulf
 * @dev Implements ERC1155 with custom fee distribution, referral system, and token deadlines
 *
 * Features:
 * - 3-tier fee system (platform, creator, referral)
 * - Configurable token metadata and mint deadlines
 * - Batch minting capabilities
 * - Creator-controlled token configuration
 *
 */
contract AP1155 is ERC1155, ReentrancyGuardTransient {

    /// @notice Platform fee amount in wei per mint
    uint256 constant PLATFORM_FEE = 8e13;

    /// @notice Struct containing fee info and creator
    struct FeeInfo {
        address feeRecipient;
        address creator;
        uint256 creatorFee;
        uint256 referralFee;
    }

    /// @notice Public variable holding fee and creator info
    FeeInfo public feeInfo;

    /// @notice Struct containing collection metadata
    struct TokenMetadata {
        string name;
        string symbol;
        string description;
        string image;
        string external_link;
    }

    /// @notice Public variable holding collection metadata
    TokenMetadata public tokenMetadata;

    /// @notice Mapping of token ID to its metadata URI
    mapping(uint256 id => string uri) public _tokenURIs;
    /// @notice Mapping of token ID to its mint deadline timestamp
    mapping(uint256 id => uint256 deadline) public _mintCloseDate;

    /**
     * @notice Emitted when a new token is configured by the creator
     * @param id Token ID that was configured
     * @param tokenURI Metadata URI for the token
     * @param deadline Timestamp when minting closes (0 for no deadline)
     * @param creator Address of the token creator
     */
    event TokenAdded(
        uint256 indexed id, string tokenURI, uint256 deadline, address indexed creator
    );

    /**
     * @notice Emitted when tokens are minted individually
     * @param minter Address that performed the mint
     * @param amount Number of tokens minted
     * @param id Token ID that was minted
     * @param referrer Address that received referral fee (address(0) if none)
     */
    event TokenMinted(
        address indexed minter, uint256 amount, uint256 indexed id, address indexed referrer
    );

    /**
     * @notice Emitted when tokens are minted in batch
     * @param minter Address that performed the batch mint
     * @param amounts Array of amounts minted for each token
     * @param ids Array of token IDs that were minted
     * @param referrer Address that received referral fees (address(0) if none)
     */
    event TokensMinted(
        address indexed minter, uint256[] amounts, uint256[] ids, address indexed referrer
    );

    /**
     * @notice Emitted when token metadata is permanently set
     * @param tokenURI Metadata URI that was set
     * @param id Token ID for which metadata was set
     */
    event PermanentURI(string tokenURI, uint256 indexed id);

    /**
     * @notice Emitted when fees are distributed during minting
     * @param platformFee Total platform fee distributed
     * @param creatorFee Total creator fee distributed
     * @param referralFee Total referral fee distributed
     * @param referrer Address that received referral fee (address(0) if none)
     */
    event FeesDistributed(
        uint256 platformFee, uint256 creatorFee, uint256 referralFee, address indexed referrer
    );

    /// @notice Thrown when platform fee transfer fails during minting
    error MintFeeFailed();
    /// @notice Thrown when non-creator attempts to configure a token
    error NotCreator();
    /// @notice Thrown when creator fee transfer fails during minting
    error CreatorFeeFailed();
    /// @notice Thrown when referral fee transfer fails during minting
    error ReferralFeeFailed();
    /// @notice Thrown when attempting to mint an unconfigured token
    error TokenNotConfigured();
    /// @notice Thrown when attempting to configure an already configured token
    error TokenAlreadyConfigured();
    /// @notice Thrown when attempting to mint after the deadline
    error MintClosed();
    /// @notice Thrown when batch mint arrays have mismatched lengths
    error BatchLengthWrong();
    /// @notice Thrown when mint amount is zero
    error ZeroAmount();
    /// @notice Thrown when provided fee is insufficient for minting
    error InsufficientFee();
    /// @notice Thrown when attempting to batch mint with empty arrays
    error EmptyBatch();

    /**
     * @notice Initializes the AP1155 contract with collection metadata and fee configuration
     * @param _metadata Base64-encoded JSON metadata for token ID 1
     * @param _feeRecipient Address that receives platform fees
     * @param _creator Address of the collection creator
     * @param _creatorFee Fee amount sent to creator per mint (in wei)
     * @param _referralFee Fee amount sent to referrer per mint (in wei)
     * @param _name Collection name for contract metadata
     * @param _symbol Collection symbol for contract metadata
     * @param _description Collection description for contract metadata
     * @param _image Collection image URL for contract metadata
     * @param _external_link Collection external link for contract metadata
     */
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

        feeInfo = FeeInfo({
            feeRecipient: _feeRecipient,
            creator: _creator,
            creatorFee: _creatorFee,
            referralFee: _referralFee
        });

        tokenMetadata = TokenMetadata({
            name: _name,
            symbol: _symbol,
            description: _description,
            image: _image,
            external_link: _external_link
        });
    }

    /**
     * @notice Internal validation and fee distribution for single token minting
     * @dev Checks token configuration, expiration, and distributes all fees
     * @param id Token ID being minted
     * @param referrer Address to receive referral fee
     * Emits FeesDistributed event with fee breakdown
     */
    function _mintChecks(uint256 id, address referrer) internal {
        require(bytes(_tokenURIs[id]).length != 0, TokenNotConfigured());

        uint256 expiration = _mintCloseDate[id];

        if (expiration != 0 && block.timestamp > expiration) {
            revert MintClosed();
        }

        (bool mintFeeOk,) = feeInfo.feeRecipient.call{ value: PLATFORM_FEE }("");
        (bool creatorFeeOk,) = feeInfo.creator.call{ value: feeInfo.creatorFee }("");

        if (referrer != address(0)) {
            (bool referralFeeOk,) = referrer.call{ value: feeInfo.referralFee }("");
            require(referralFeeOk, ReferralFeeFailed());
        } else {
            (bool defaultReferral,) = feeInfo.feeRecipient.call{ value: feeInfo.referralFee }("");
            require(defaultReferral, ReferralFeeFailed());
        }

        require(mintFeeOk, MintFeeFailed());
        require(creatorFeeOk, CreatorFeeFailed());

        emit FeesDistributed({
            platformFee: PLATFORM_FEE,
            creatorFee: feeInfo.creatorFee,
            referralFee: feeInfo.referralFee,
            referrer: referrer
        });
    }

    /**
     * @notice Internal validation and fee distribution for batch token minting
     * @dev Checks all token configurations, expirations, and distributes all fees
     * @param ids Array of token IDs being minted
     * @param referrer Address to receive referral fees
     * Emits FeesDistributed event with total fee breakdown
     */
    function _mintChecks(uint256[] calldata ids, address referrer) internal {
        uint256 lengths = ids.length;

        for (uint256 i = 0; i < lengths; i++) {
            require(bytes(_tokenURIs[ids[i]]).length != 0, TokenNotConfigured());

            uint256 expiration = _mintCloseDate[ids[i]];

            if (expiration != 0 && block.timestamp > expiration) {
                revert MintClosed();
            }
        }

        (bool mintFeeOk,) = feeInfo.feeRecipient.call{ value: PLATFORM_FEE * lengths }("");
        (bool creatorFeeOk,) = feeInfo.creator.call{ value: feeInfo.creatorFee * lengths }("");

        if (referrer != address(0)) {
            (bool referralFeeOk,) = referrer.call{ value: feeInfo.referralFee * lengths }("");
            require(referralFeeOk, ReferralFeeFailed());
        } else {
            (bool defaultReferral,) =
                feeInfo.feeRecipient.call{ value: feeInfo.referralFee * lengths }("");
            require(defaultReferral, ReferralFeeFailed());
        }

        require(mintFeeOk, MintFeeFailed());
        require(creatorFeeOk, CreatorFeeFailed());

        emit FeesDistributed({
            platformFee: PLATFORM_FEE * lengths,
            creatorFee: feeInfo.creatorFee * lengths,
            referralFee: feeInfo.referralFee * lengths,
            referrer: referrer
        });
    }

    /**
     * @notice Configures a new token with metadata and optional mint deadline
     * @dev Only callable by the creator. Mints 1 token to creator as proof of ownership
     * @param id Token ID to configure
     * @param tokenURI Metadata URI for the token (should be base64-encoded JSON)
     * @param expiration Timestamp when minting closes (0 for no deadline)
     * Emits TokenAdded event with token configuration details
     * Emits PermanentURI event for metadata permanence
     */
    function configureToken(uint256 id, string memory tokenURI, uint256 expiration) external {
        require(msg.sender == feeInfo.creator, NotCreator());
        require(bytes(_tokenURIs[id]).length == 0, TokenAlreadyConfigured());
        _mintCloseDate[id] = expiration;
        _tokenURIs[id] = tokenURI;
        _mint(feeInfo.creator, id, 1, "");

        emit TokenAdded({ id: id, tokenURI: tokenURI, deadline: expiration, creator: msg.sender });
        emit PermanentURI({ tokenURI: tokenURI, id: id });
    }

    /**
     * @notice Returns collection-level metadata for marketplaces
     * @dev Follows OpenSea contract-level metadata standard
     * @return JSON string containing collection name, description, image, and external link
     */
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

    /**
     * @notice Returns the metadata URI for a specific token
     * @dev Overrides ERC1155.uri() to return custom token URIs
     * @param id Token ID to query
     * @return Metadata URI string for the token
     */
    function uri(
        uint256 id
    ) public view override returns (string memory) {
        return _tokenURIs[id];
    }

    /**
     * @notice Mints a single token with fee distribution
     * @dev Validates token configuration, checks deadlines, and distributes fees
     * @param id Token ID to mint
     * @param amount Number of tokens to mint (must be > 0)
     * @param to Address to receive the minted tokens
     * @param referrer Address to receive referral fee (address(0) for no referral)
     * Emits TokenMinted event with mint details
     */
    function mint(
        uint256 id,
        uint256 amount,
        address to,
        address referrer
    ) external payable nonReentrant {
        uint256 totalFee = PLATFORM_FEE + feeInfo.creatorFee + feeInfo.referralFee;
        require(msg.value >= totalFee, InsufficientFee());
        require(amount > 0, ZeroAmount());
        _mintChecks(id, referrer);
        _mint(to, id, amount, "");
        emit TokenMinted({ minter: msg.sender, amount: amount, id: id, referrer: referrer });
    }

    /**
     * @notice Mints multiple tokens in a single transaction with fee distribution
     * @dev Validates all token configurations, checks deadlines, and distributes fees
     * @param ids Array of token IDs to mint
     * @param amounts Array of amounts to mint for each token ID
     * @param to Address to receive all minted tokens
     * @param referrer Address to receive referral fees (address(0) for no referral)
     * Emits TokensMinted event with batch mint details
     */
    function batchMint(
        uint256[] calldata ids,
        uint256[] calldata amounts,
        address to,
        address referrer
    ) external payable nonReentrant {
        uint256 lengths = ids.length;
        uint256 totalFee = (PLATFORM_FEE + feeInfo.creatorFee + feeInfo.referralFee) * lengths;
        require(msg.value >= totalFee, InsufficientFee());
        require(lengths > 0, EmptyBatch());
        require(lengths == amounts.length, BatchLengthWrong());
        _mintChecks(ids, referrer);
        _batchMint(to, ids, amounts, "");
        emit TokensMinted({ minter: msg.sender, amounts: amounts, ids: ids, referrer: referrer });
    }

}
