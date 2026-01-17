// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract NexusNFT is ERC721, ERC721Enumerable, Ownable {
    using Strings for uint256;

    uint256 private _tokenId;
    uint256 public constant MINTING_COST = 0.001 ether;
    uint256 public constant MAX_SUPPLY = 100;
    string public baseURI = "https://ipfs.io/ipfs/bafybeidtjn57uec7earkgxnhbyupfdnjok2jecr5nsr5nw5q5ixvghk2hi";

    event NFTMinted(address indexed minter, uint256 indexed tokenId);

    constructor() ERC721("NexusNFT", "N-NFT") Ownable(msg.sender) {}

    function safeMinting() public payable {
        require(msg.value >= MINTING_COST, "insufficient funds");
        require(totalSupply() < MAX_SUPPLY, "Max supply reached");
        
        _tokenId++;
        uint256 tokenId = _tokenId;
        
        _safeMint(msg.sender, tokenId);
        
        emit NFTMinted(msg.sender, tokenId);
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
       require(_ownerOf(tokenId) != address(0), "URI query for nonexistent token");


         string memory metadata = Base64.encode(abi.encodePacked( '{',
                    '"name":"NexusNFT #', tokenId.toString(), '",',
                    '"description":"A futuristic cyberpunk NexusNFT.",',
                    '"image":"', baseURI, '",',
                    '"attributes":[',
                    '{"trait_type":"Theme","value":"Cyberpunk"},',
                    '{"trait_type":"Energy","value":"Neon"},',
                    '{"trait_type":"Rarity","value":"Legendary"}',
                    ']',
                '}'
            )
        );

        return string(abi.encodePacked("data:application/json;base64,", metadata));
    }

    function setBaseUri(string memory _newBaseUri) external onlyOwner {
        baseURI = _newBaseUri;
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No funds to withdraw");
        
        (bool success, ) = payable(owner()).call{value: balance}("");
        require(success, "Withdrawal failed");
    }

    // Required overrides

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
