import { expect } from "chai";
import hre from "hardhat";
const { ethers } = await hre.network.connect();

describe("RWA Asset", function () {
  let asset, rwaFactory;
  let owner, user1, user2, user3;

  beforeEach(async () => {
    [owner, user1, user2, user3] = await ethers.getSigners();

    //Deploy Factory
    const RWAFactory = await ethers.getContractFactory("RWAAssetFactory");
    rwaFactory = await RWAFactory.deploy();
    await rwaFactory.connect(owner).deployContract();
    const assetAddress = await rwaFactory.getAsset(owner.address);

    //Attach asset address to asset
    asset = await ethers.getContractAt("RWAAsset", assetAddress);
  });

  it("allows owner to mint asset functions", async () => {
    await asset.mintAsset(100, owner.address, "Some URL");

    const balance = await asset.balanceOf(owner.address, 1);
    expect(balance).to.equal(100);

    expect(await asset.viewTotalFractions(1)).to.equal(100);

    expect(await asset.viewMetadata(1)).to.equal("Some URL");
  });

  it("prevent non-owner from minting", async () => {
    expect(asset.connect(user1).mintAsset(100, owner.address, "Some URL")).to.be
      .revert;
  });
});
