// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {NexusNFT} from "../src/NexusNFT.sol";
import {Test} from "../lib/forge-std/src/Test.sol";

contract testNexusNFT is Test {
    NexusNFT public myNft;

    address public owner=makeAddr("owner");
    address public user1=makeAddr("user1");
    address public user2=makeAddr("user2");

    uint256 constant MINTING_COST=0.001 ether;
    uint256 constant MAX_SUPPLY=100;

function setUp()public {
    vm.prank(owner);
    myNft=new NexusNFT();
    
    //fund test accounts
    vm.deal(user1, 100 ether);
    vm.deal(user2, 100 ether);
}
            //MINT TESTS: 2 additional cause of the two require statements
function testMintingWorks()public {
    vm.prank(user1);
    myNft.safeMinting{value: 0.001 ether}();

    vm.prank(user2);
    myNft.safeMinting{value: 0.001 ether}();

    assertEq(myNft.totalSupply(),2);
    assertEq(myNft.ownerOf(1),user1);
    assertEq(myNft.ownerOf(2), user2);
}
function testMintingWithInsufficientFund() public{
    vm.prank(user1);
    vm.expectRevert("insufficient funds");
    myNft.safeMinting{value: 0.0001 ether}();
}

function  testMintingAboveMaxSupply() public {
    for (uint256 i=0; i < myNft.MAX_SUPPLY(); i++){
    vm.prank(user1);
    myNft.safeMinting{value: 0.001 ether}();
    }

    vm.prank(user1);
    vm.expectRevert("Max supply reached");
    myNft.safeMinting{value: 0.001 ether}();
}
            //TOKENURI TESTS
function testTokenURINonexistentTokenReverts() public {
        vm.expectRevert("URI query for nonexistent token");
        myNft.tokenURI(1);
    }

function testTokenURI() public {
    vm.prank(user1);
    myNft.safeMinting{value: 0.001 ether}();

    string memory uri=myNft.tokenURI(1);
    assertTrue(bytes(uri).length > 0);
}

        //WITHDRAW Test
function testWithdrawalByOwner() public {
    vm.prank (user1);
    myNft.safeMinting{value :0.001 ether}();

    uint256 ownerBalanceBefore=owner.balance;

    vm.prank(owner);
    myNft.withdraw();

    assertEq(address(myNft).balance, 0);
    assertEq(owner.balance, ownerBalanceBefore+0.001 ether);
}
function testWithdrawWithNoFunds() public {
    // No minting don happen, so contract balance na 0
    vm.prank(owner);
    vm.expectRevert("No funds to withdraw");
    myNft.withdraw();
}
function testOnlyOwnerCanWithdraw() public {
    // First mint to add funds
    vm.prank(user1);
    myNft.safeMinting{value: 0.001 ether}();
    
    // Try to withdraw as non-owner
    vm.prank(user1);
    vm.expectRevert(); // Will revert with Ownable error
    myNft.withdraw();
}

        //SETBASEURI TEST
function testSetBaseUri() public {
    string memory newBaseUri="https://new-ipfs-link.com/";

    vm.prank(owner);
    myNft.setBaseUri(newBaseUri);

    assertEq(myNft.baseURI(),newBaseUri);
}
//No require statement for onlyOwner beign,but just for fun
function testOnlyOwnerCanSetBaseUri()public {
    string memory newUri="https://new-ipfs-link.com/";

    vm.prank(user1);
    vm.expectRevert(); //no revert statement cause i didnt write a require statement in the contract with a statement to use here
    myNft.setBaseUri(newUri);
}
// Test supportsInterface
function testSupportsInterface() public view {
    bytes4 erc721InterfaceId = 0x80ac58cd;
    assertTrue(myNft.supportsInterface(erc721InterfaceId));
}



}



