//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {NexusMarketPlace} from "../src/NexusMarketPlace.sol";
import {NexusNFT} from "../src/NexusNFT.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract testNexusMarketPlace is Test{
    NexusMarketPlace public NMP;
    NexusNFT public myNft;

    address public owner= makeAddr ("owner");
    address public seller= makeAddr ("seller");
    address public buyer= makeAddr ("buyer");
    address public user3 = makeAddr("user3"); //added cause i want to test for buying when the seller no longer owns NFT,nothing more

    uint256 constant MINTING_COST = 0.5 ether;
    uint256 constant LIST_PRICE = 1 ether;

function setUp()public {
    vm.startPrank(owner);
    myNft=new NexusNFT();
    NMP=new NexusMarketPlace(address(myNft));
    vm.stopPrank();

    vm.deal(seller, 100 ether);
    vm.deal(buyer, 100 ether);

            //seller mints 5 NFT
    vm.startPrank(seller);
    for(uint256 i=0; i<5; i++){
    myNft.safeMinting{value: 0.5 ether}();
    }
            //set approval for all NFTs
    myNft.setApprovalForAll(address(NMP),true);
    vm.stopPrank();
}

            /////////////LISTING TESTS
function testCanListNft() public {
    vm.startPrank(seller);
    NMP.listNFT(1, 1 ether);   // or NMP.listNFT(1, LIST_PRICE)
            //verify listing
    (uint256 tokenId, address listingSeller, uint256 price, bool active)= NMP.listings(1);
    assertEq(tokenId, 1);
    assertEq(listingSeller, seller); 
    assertEq(price, 1 ether);
    assertTrue(active);
    assertTrue(NMP.hasActiveListing(seller));
    assertEq(NMP.sellerActiveTokenId(seller), 1);   
}

function test_RevertListingWithoutApproval () public {
    vm.prank(seller);
    myNft.setApprovalForAll(address(NMP), false);

    vm.prank(seller);
    vm.expectRevert("Marketplace not approved");
    NMP.listNFT(1, 1 ether);
}

function test_RevertMultipleActiveListings ()public {
    vm.prank(seller);
    NMP.listNFT(1, 1 ether);

    vm.prank(seller);
    vm.expectRevert("You already have an active listing!");
    NMP.listNFT(2, 1 ether);
}

function test_RevertListingNFTNotOwner()public {
    vm.prank (buyer);
    vm.expectRevert("You don't own this NFT");
    NMP.listNFT(1, 1 ether);
}

            //NFT BUYING TESTS
function testBuyNFT() public {
    vm.prank(seller);
    NMP.listNFT(1, 1 ether);

    uint256 sellerBalanceBefore =seller.balance;
    uint256 buyerBalanceBefore = buyer.balance;

    vm.prank(buyer);
    NMP.buyNFT{value: 1 ether}(1);      // or NMP.buyNFT{value: LIST_PRICE}(1);

    assertEq(myNft.ownerOf(1), buyer);
    assertEq(seller.balance, sellerBalanceBefore + 1 ether);
    assertEq(buyer.balance, buyerBalanceBefore - 1 ether);

     // Just to Verify that listing is inactive;doesnt affect test
    (, , , bool active) = NMP.listings(1);
    assertFalse(active);
    assertFalse(NMP.hasActiveListing(seller));
    assertEq(NMP.sellerActiveTokenId(seller), 0);
}

function testBuyingWithInsufficientAmount() public {
    vm.prank(seller);
    NMP.listNFT(1, 1 ether);

    vm.prank(buyer);
    vm.expectRevert("Insufficient payment");
    NMP.buyNFT{value: 0.5 ether}(1);
}

function testSellerBuyingPersonalNFT ()public {
    vm.prank(seller);
    NMP.listNFT(1, 1 ether);

    vm.prank(seller);
    vm.expectRevert("Cannot buy your own NFT");
    NMP.buyNFT{value: 1 ether}(1);
}

function testBuyingNFTNotListed () public {
    vm.prank(buyer);
    vm.expectRevert("NFT is not listed");
    NMP.buyNFT{value: 0.1 ether}(1);
}

function testSellerNoLongerOwnsNFT () public {
    vm.prank(seller);
    NMP.listNFT(1, 1 ether);

    vm.prank(seller);
    myNft.transferFrom(seller, user3, 1);

    vm.prank(buyer);
    vm.expectRevert("Seller no longer owns NFT");
    NMP.buyNFT{value: 1 ether}(1);
}

        ////////////TESTS FOR DELISTING NFTS
function testDelistNFT() public {
    vm.prank(seller);
    NMP.listNFT(1, 1 ether);

    vm.prank(seller);
    NMP.delistNFT(1);

            // Just to Verify that listing is inactive;doesnt affect test
    (, , , bool active) = NMP.listings(1);
    assertFalse(active);
    assertFalse(NMP.hasActiveListing(seller));
    assertEq(NMP.sellerActiveTokenId(seller), 0); 
}

function test_CanListAfterDelisting() public {
        vm.prank(seller);
        NMP.listNFT(1, 1 ether);
    
        vm.prank(seller);
        NMP.delistNFT(1);
        
        vm.prank(seller);
        NMP.listNFT(2, 1 ether);
        
        // Verify new listing
        (uint256 tokenId, address listingSeller, uint256 price, bool active) = NMP.listings(2);
        assertEq(tokenId, 2);
        assertEq(listingSeller, seller);
        assertEq(price, LIST_PRICE);
        assertTrue(active);
        assertTrue(NMP.hasActiveListing(seller));
        assertEq(NMP.sellerActiveTokenId(seller), 2);
    }

function testDelistNotListed ()public {
    vm.prank(seller);
    vm.expectRevert("NFT is not listed");
    NMP.delistNFT(1);
}
function testDelisterNotSeller () public {
    vm.prank(seller);
    NMP.listNFT(1, 1 ether);

    vm.prank(buyer);
    vm.expectRevert("You are not the seller");
    NMP.delistNFT(1);
}

function testGetActiveListing() public {
        vm.prank(seller);
        NMP.listNFT(1, 1 ether);
        
        // Get active listing
        NexusMarketPlace.Listing memory listing = NMP.getActiveListing(seller);
        
        assertEq(listing.tokenId, 1);
        assertEq(listing.seller, seller);
        assertEq(listing.price, 1 ether);
        assertTrue(listing.active);
    }
    
    function test_RevertGetActiveListingNoListing() public {
        // Try to get active listing when seller has no listing
        vm.expectRevert("Seller has no active listing");
        NMP.getActiveListing(seller);
    }

}
