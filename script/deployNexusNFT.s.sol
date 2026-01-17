//SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;
import {Script} from "../lib/forge-std/src/Script.sol";
import {NexusNFT} from "../src/NexusNFT.sol";

contract deployNexusNFT is Script {
    function run() external returns(NexusNFT){
        uint256 deployerPrivateKey=vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        NexusNFT nexusNFT = new NexusNFT();

        vm.stopBroadcast();

        return nexusNFT;
    }


}