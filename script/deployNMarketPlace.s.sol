//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {Script} from "../lib/forge-std/src/Script.sol";
import {NexusNFT} from "../src/NexusNFT.sol";
import {NexusMarketPlace} from "../src/NexusMarketPlace.sol";
import {console} from "forge-std/console.sol";

contract DeployNexusMarketPlace is Script {
    function run() external returns (NexusNFT,NexusMarketPlace){
        uint256 deployerPrivateKey=vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        NexusNFT nexusNFT=new NexusNFT();
        console.log("NexusNFT deployed at:", address(nexusNFT));

        NexusMarketPlace marketplace=new NexusMarketPlace(address(nexusNFT));
        console.log("NexusMarketPlace deployed at:", address(marketplace));
        
        vm.stopBroadcast();

        return(nexusNFT, marketplace);
    }


}



                //CONTRACT ADDRESSES AFTER DEPLOYMENT
//NexusNFT deployed at: 0xca091577EC1A06d9f2970eaCA441594D11F2df68
//NexusMarketPlace deployed at: 0xC2491f97F52bf7F9dFe8A6FaE7e3e2D1b03276F6
