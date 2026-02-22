// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.20;
import {RWAAsset} from "./RWAAsset.sol"; // Ensure this import path is correct

// <<What's Happening>>
// Factory deploys per-user RWAAsset instances. Each instance is owned by the deployer (user),
// allowing them to mint multiple assets/fractions via functions (no new deployments per asset).
// Factory tracks all instances for counting/displaying "how many people deployed" and listing others.
contract RWAAssetFactory {
    address[] public allDeployedContracts;
    mapping(address => address) public userToContract;

    event ContractDeployed(address indexed user, address contractAddress);

    /**
     * @dev Deploy a new RWAAsset instance for the user
     */
    function deployContract() public {
        require(userToContract[msg.sender] == address(0), "Already deployed");
        address assets = address(new RWAAsset(msg.sender));
        userToContract[msg.sender] = assets;
        allDeployedContracts.push(assets);
        emit ContractDeployed(msg.sender, assets);
    }

    function getAllDeployedAssets() public view returns (address[] memory) {
        return allDeployedContracts;
    }
    function totalDeployedAssets() public view returns (uint256) {
        return allDeployedContracts.length;
    }
    function getAsset(address user) public view returns (address) {
        return userToContract[user];
    }
}
