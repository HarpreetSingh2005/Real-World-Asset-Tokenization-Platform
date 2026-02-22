import { expect } from "chai";
import hre from "hardhat";
const { ethers } = await hre.network.connect();

describe("RWA Factory", function () {
  let rwaFactory;
  let owner, user1, user2, user3;

  beforeEach(async () => {
    [owner, user1, user2, user3] = await ethers.getSigners();

    //Deploy Factory
    const RWAFactory = await ethers.getContractFactory("RWAAssetFactory");
    rwaFactory = await RWAFactory.deploy();
  });
  it("User deploy the RWAAsset contract", async function () {
    //Seller deploys their asset contract
    await rwaFactory.connect(owner).deployContract();
    await rwaFactory.connect(user1).deployContract();
    const assetAddress_1 = await rwaFactory.getAsset(owner.address);
    const assetAddress_2 = await rwaFactory.getAsset(user1.address);
    const allDeployedAssets = await rwaFactory.getAllDeployedAssets();

    expect(allDeployedAssets[0]).to.equal(assetAddress_1);
    expect(allDeployedAssets[1]).to.equal(assetAddress_2);
    expect(assetAddress_2).to.not.equal(ethers.ZeroAddress);
  });
  it("No Duplicate deployment", async () => {
    await rwaFactory.connect(owner).deployContract();
    await expect(rwaFactory.connect(owner).deployContract()).to.be.revertedWith(
      "Already deployed",
    );
  });
});
