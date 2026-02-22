// SPDX-License-Identifier:GPL-3.0
pragma solidity >=0.8.20;
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";
import {
    ERC1155Holder
} from "@openzeppelin/contracts/token/ERC1155/utils/ERC1155Holder.sol";

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract RWAAuction is Ownable, ERC1155Holder, ReentrancyGuard {
    IERC1155 public immutable rwaAsset; // Reference to the asset contract
    struct Auction {
        uint256 assetId;
        uint256 fractions;
        address seller;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool ended;
    }

    mapping(uint256 => Auction) public auctions;
    uint256 public auctionCount = 0;

    event AuctionStarted(
        uint256 indexed auctionId,
        uint256 assetId,
        uint256 fractions,
        uint256 startingPrice,
        uint256 duration
    );
    event BidPlaced(uint256 indexed auctionId, address bidder, uint256 amount);
    event AuctionEnded(
        uint256 indexed auctionId,
        address winner,
        uint256 amount
    );

    constructor(address _rwaAssetAddress) Ownable(msg.sender) {
        rwaAsset = IERC1155(_rwaAssetAddress);
    }

    /**
     * @dev Start a new auction for fractions of an asset.
     * @param assetId The asset ID.
     * @param fractions Number of fractions to sell.
     * @param startingPrice Minimum bidding price.
     * @param duration Auction duration in seconds. (e.g., 900 for 15 min, 86400 for 24 hours).
     */
    //Not making it onlyOwner because we want to allow anyone to start an auction with a valid amount of fraction of the asset and also adding a fees to avoid SPAMMING
    function startAuction(
        uint256 assetId,
        uint256 fractions,
        uint256 startingPrice,
        uint256 duration
    ) public payable nonReentrant {
        require(fractions > 0, "You don't have valid fraction of the asset");
        require(
            rwaAsset.balanceOf(msg.sender, assetId) >= fractions,
            "Insufficient fractions"
        );
        require(duration > 0, "Duration must be greater than zero");
        require(msg.value >= 0.01 ether, "Auction fee");

        rwaAsset.safeTransferFrom(
            msg.sender,
            address(this),
            assetId,
            fractions,
            ""
        );

        uint256 auctionId = auctionCount;
        auctions[auctionId] = Auction({
            assetId: assetId,
            fractions: fractions,
            seller: msg.sender,
            highestBid: startingPrice,
            highestBidder: address(0),
            endTime: block.timestamp + duration,
            ended: false
        });

        auctionCount++;

        emit AuctionStarted(
            auctionId,
            assetId,
            fractions,
            startingPrice,
            duration
        );
    }

    /**
     * @dev Place a bid on an active auction.
     * @param auctionId The auction ID.
     */

    //Storage: Means we're referencing the on-chain stored data (not a memory copy). Changes to auction persist.
    function bid(uint256 auctionId) public payable nonReentrant {
        Auction storage auction = auctions[auctionId];
        require(
            msg.sender != auction.highestBidder,
            "Your bid is already there"
        );
        require(block.timestamp < auction.endTime, "Auction has ended.");
        require(!auction.ended, "Auction already finalized"); //Even if time hasn't passed, if someone called endAuction early
        require(
            msg.value > auction.highestBid,
            "Bid must be higher than current highest bid."
        );

        if (auction.highestBidder != address(0)) {
            (bool success, ) = payable(auction.highestBidder).call{
                value: auction.highestBid
            }("");
            require(success, "Transfer failed.");
        }

        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;
        emit BidPlaced(auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 auctionId) public {
        Auction storage auction = auctions[auctionId];
        require(
            block.timestamp >= auction.endTime,
            "Auction hasn't ended yet."
        );
        require(!auction.ended, "Auction already ended");
        auction.ended = true;
        if (auction.highestBidder != address(0)) {
            rwaAsset.safeTransferFrom(
                address(this),
                auction.highestBidder,
                auction.assetId,
                auction.fractions,
                ""
            );
            (bool success, ) = payable(auction.seller).call{
                value: auction.highestBid
            }("");
            require(success, "Transfer to seller failed.");

            emit AuctionEnded(
                auctionId,
                auction.highestBidder,
                auction.highestBid
            );
        } else {
            //No bids: Return the fraction to owner
            rwaAsset.safeTransferFrom(
                address(this),
                auction.seller,
                auction.assetId,
                auction.fractions,
                ""
            );
            emit AuctionEnded(auctionId, address(0), 0);
        }
        (bool success, ) = payable(auction.seller).call{value: 0.01 ether}("");
        require(success, "Auction fee transfer failed.");
    }
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC1155Holder) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
