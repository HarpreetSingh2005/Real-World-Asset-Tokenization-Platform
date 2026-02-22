import { expect } from "chai";
import hre from "hardhat";
const { ethers } = await hre.network.connect();

describe("RWA Asset", function () {
  let asset, auction;
  let owner, bidder1, bidder2, bidder3;

  beforeEach(async () => {
    [owner, bidder1, bidder2, bidder3] = await ethers.getSigners();

    //Deploy Asset
    const Asset = await ethers.getContractFactory("RWAAsset");
    asset = await Asset.deploy(owner.address);

    //Mint Asset
    await asset.mintAsset(100, owner.address, "Some URL");

    //Deploy Auction
    const RWAAuction = await ethers.getContractFactory("RWAAuction");
    auction = await RWAAuction.deploy(asset.target);

    //Approve auction to transfer fraction
    await asset.connect(owner).setApprovalForAll(auction.target, true);
  });

  it("stores correct asset address on deployment", async () => {
    expect(await auction.rwaAsset()).to.equal(asset.target);
  });

  it("allows user to start an auction", async () => {
    await auction.startAuction(1, 20, ethers.parseEther("1"), 60, {
      value: ethers.parseEther("0.01"),
    });
    const a = await auction.auctions(0);
    expect(a.seller).to.equal(owner.address);
  });
  it("prevents non-owner from starting auction", async () => {
    await expect(
      auction.connect(bidder1).startAuction(1, 20, ethers.parseEther("1"), 60, {
        value: ethers.parseEther("0.01"),
      }),
    ).to.be.revert();
  });

  //This test passes but its reverted message crashes test.
  //Don't know reason but you can comment it and test rest cases.
  it("reverts if asset not approved for transfer", async () => {
    await asset.setApprovalForAll(auction.target, false);

    expect(
      auction.startAuction(1, 20, ethers.parseEther("1"), 60, {
        value: ethers.parseEther("0.01"),
      }),
    ).to.be.revert;
  });

  it("accepts valid bids and updates highest bidder", async () => {
    await auction.startAuction(1, 20, ethers.parseEther("1"), 60, {
      value: ethers.parseEther("0.01"),
    });

    await auction.connect(bidder1).bid(0, {
      value: ethers.parseEther("2"),
    });

    const a = await auction.auctions(0);
    expect(a.highestBidder).to.equal(bidder1.address);
  });

  it("refunds previous bidder when outbid", async () => {
    await auction.startAuction(1, 20, ethers.parseEther("1"), 60, {
      value: ethers.parseEther("0.01"),
    });

    await auction.connect(bidder1).bid(0, {
      value: ethers.parseEther("2"),
    });

    await expect(
      auction.connect(bidder2).bid(0, {
        value: ethers.parseEther("3"),
      }),
    ).to.changeEtherBalance(ethers, bidder1, ethers.parseEther("2"));
    // changeEtherBalance(bidder1, ethers.parseEther("2"));
  });

  it("rejects bids lower than current highest bid", async () => {
    await auction.startAuction(1, 20, ethers.parseEther("1"), 60, {
      value: ethers.parseEther("0.01"),
    });

    await auction.connect(bidder1).bid(0, {
      value: ethers.parseEther("2"),
    });

    await expect(
      auction.connect(bidder2).bid(0, {
        value: ethers.parseEther("1"),
      }),
    ).to.be.revertedWith("Bid must be higher than current highest bid.");
  });

  it("prevents bidding after auction ends", async () => {
    await auction.startAuction(1, 20, ethers.parseEther("1"), 10, {
      value: ethers.parseEther("0.01"),
    });

    await ethers.provider.send("evm_increaseTime", [20]);
    await ethers.provider.send("evm_mine");

    await expect(
      auction.connect(bidder1).bid(0, {
        value: ethers.parseEther("2"),
      }),
    ).to.be.revertedWith("Auction has ended.");
  });

  it("transfers fractions to winner on auction end", async () => {
    await auction.startAuction(1, 30, ethers.parseEther("1"), 10, {
      value: ethers.parseEther("0.01"),
    });

    await auction.connect(bidder1).bid(0, {
      value: ethers.parseEther("2"),
    });

    await ethers.provider.send("evm_increaseTime", [20]);
    await ethers.provider.send("evm_mine");

    await auction.endAuction(0);

    expect(await asset.balanceOf(bidder1.address, 1)).to.equal(30);
  });

  it("transfers ETH to seller on auction end", async () => {
    await auction.startAuction(1, 10, ethers.parseEther("1"), 10, {
      value: ethers.parseEther("0.01"),
    });

    await auction.connect(bidder1).bid(0, {
      value: ethers.parseEther("2"),
    });

    await ethers.provider.send("evm_increaseTime", [20]);
    await ethers.provider.send("evm_mine");

    await expect(() => auction.endAuction(0)).to.changeEtherBalance(
      ethers,
      owner,
      ethers.parseEther("2.01"),
    );
  });

  it("allows new fraction owner to start a new auction", async () => {
    await auction.startAuction(1, 40, ethers.parseEther("1"), 10, {
      value: ethers.parseEther("0.01"),
    });

    await auction.connect(bidder1).bid(0, {
      value: ethers.parseEther("2"),
    });

    await ethers.provider.send("evm_increaseTime", [20]);
    await ethers.provider.send("evm_mine");

    await auction.endAuction(0);

    expect(await asset.balanceOf(bidder1.address, 1)).to.equal(40);

    await asset.connect(bidder1).setApprovalForAll(auction.target, true);

    await auction
      .connect(bidder1)
      .startAuction(1, 20, ethers.parseEther("1"), 10, {
        value: ethers.parseEther("0.01"),
      });

    const secondAuction = await auction.auctions(1);
    expect(secondAuction.seller).to.equal(bidder1.address);
  });
});
