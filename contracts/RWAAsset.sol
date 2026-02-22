// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;

import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract RWAAsset is ERC1155, Ownable {
    uint256 private _nextAssetId = 1;

    //Mapping an id to asset metadata URIs (IPFS links)
    mapping(uint256 => string) public assetMetadata;
    //Mapping an asset to its total fractions
    mapping(uint256 => uint256) public totalSupply;

    event AssetMinted(
        uint256 indexed assetId,
        uint256 totalFractions,
        address initialOwner,
        string metadataURI
    );

    constructor(address initialOwner) ERC1155("") Ownable(initialOwner) {}

    /**
     * @dev Mint a new asset.
     * @param totalFractions Number of fractions to create.
     * @param initialOwner Address to recieve all fractions initiallu.
     * @param metadata IPFS URI for the asset metadata.
     */

    function mintAsset(
        uint256 totalFractions,
        address initialOwner,
        string memory metadata
    ) public onlyOwner {
        uint256 assetId = _nextAssetId;
        _nextAssetId += 1;
        require(totalFractions > 0, "Total fractions must be greater than 0");
        _mint(initialOwner, assetId, totalFractions, "");
        assetMetadata[assetId] = metadata;
        totalSupply[assetId] = totalFractions;
        emit AssetMinted(assetId, totalFractions, initialOwner, metadata);
        
    }

    /**
     * @dev View the total fractions of an asset
     * @param assetId The asset ID
     * @return The total fractions
     */

    function viewTotalFractions(uint256 assetId) public view returns (uint256) {
        return totalSupply[assetId];
    }

    /**
     * @dev View the metadata of an asset
     * @param assetId The asset ID
     * @return The metadata
     */
    function viewMetadata(uint256 assetId) public view returns (string memory) {
        return assetMetadata[assetId];
    }
}