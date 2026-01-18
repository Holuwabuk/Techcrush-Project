//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {NexusNFT} from "../src/NexusNFT.sol";
import {ReentrancyGuard} from "../lib/openzeppelin-contracts/contracts/utils/ReentrancyGuard.sol";

contract NexusMarketPlace is ReentrancyGuard {

  struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool active;
    }

    NexusNFT public myNFT;

    mapping(uint256 => Listing) public listings;     // The main storage: "For NFT #5, here's all the listing details", You can look up any token ID to see if it's listed and get its info
    mapping(address => bool) public hasActiveListing;  // Does this address currently have an active listing?" Prevents sellers from listing multiple NFTs simultaneously (design choice)
    mapping(address => uint256) public sellerActiveTokenId; // Which specific NFT does this seller have listed?

constructor(address _nftContract) {
    myNFT = NexusNFT(_nftContract);
    }

function listNFT(uint256 tokenId, uint256 price) external {
        require(price > 0, "Price must be greater than 0");
        require(myNFT.ownerOf(tokenId) == msg.sender, "You don't own this NFT");
        require(!hasActiveListing[msg.sender], "You already have an active listing!");
        require(myNFT.getApproved(tokenId) == address(this) || myNFT.isApprovedForAll(msg.sender, address(this)),"Marketplace not approved");

        listings[tokenId] = Listing({
            tokenId: tokenId,
            seller: msg.sender,
            price: price,
            active: true
        });

        hasActiveListing[msg.sender] = true;
        sellerActiveTokenId[msg.sender] = tokenId;
    }

  function buyNFT(uint256 tokenId) external payable nonReentrant {
        Listing storage listing = listings[tokenId];
        
        require(listing.active, "NFT is not listed");
        require(msg.value >= listing.price, "Insufficient payment");
        require(msg.sender != listing.seller, "Cannot buy your own NFT");
        require(myNFT.ownerOf(tokenId) == listing.seller, "Seller no longer owns NFT");

        address seller = listing.seller;
        uint256 price = listing.price;

        // Update state BEFORE transfers
        listing.active = false;
        hasActiveListing[seller] = false;
        sellerActiveTokenId[seller] = 0;

        // Transfer NFT to buyer
        myNFT.safeTransferFrom(seller, msg.sender, tokenId);

        // Transfer ETH to seller
        (bool success, ) = payable(seller).call{value: price}("");
        require(success, "ETH transfer failed");

        // Refund excess
        if (msg.value > price) {
            (bool refundSuccess, ) = payable(msg.sender).call{value: msg.value - price}("");
            require(refundSuccess, "Refund failed");
        }
  }
    function delistNFT(uint256 tokenId) external {
        Listing storage listing = listings[tokenId];
        
        require(listing.active, "NFT is not listed");
        require(listing.seller == msg.sender, "You are not the seller");

        listing.active = false;
        hasActiveListing[msg.sender] = false;
        sellerActiveTokenId[msg.sender] = 0;
    }

function getActiveListing(address seller) external view returns (Listing memory) {
    require(hasActiveListing[seller], "Seller has no active listing");
    uint256 tokenId = sellerActiveTokenId[seller];
    return listings[tokenId];
    }
    
}


















