// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.30;

import { APFactory } from "../src/APFactory.sol";
import { Script, console } from "forge-std/Script.sol";

contract APFactoryScript is Script {

    APFactory public apFactory;

    function setUp() public { }

    function run() public {
        vm.startBroadcast();

        apFactory = new APFactory();
        string memory metadata =
            '{"name":"Test NFT #1","description":"A test NFT for the AP1155 contract deployment","image":"https://media.mulf.wtf/testnft-img.png","attributes":[{"trait_type":"Collection","value":"Test Collection"},{"trait_type":"Rarity","value":"Common"}],"external_url":"https://your-website.com","background_color":"000000"}';

        address deployedAP1155 = apFactory.deployNew(
            metadata,
            1000,
            500,
            "Test Collection",
            "TEST",
            "A test collection for the AP1155 contract deployment",
            "https://media.mulf.wtf/collection-img.png",
            "https://mulf.wtf"
        );

        console.log("Deployed AP1155 address:", deployedAP1155);

        // ABI encode constructor args for the deployed AP1155 contract
        bytes memory constructorArgs = abi.encode(
            metadata,
            apFactory.feeRecipient(), // actual feeRecipient from factory
            msg.sender, // actual creator (script deployer)
            1000, // creatorFee
            500, // referralFee
            "Test Collection",
            "TEST", 
            "A test collection for the AP1155 contract deployment",
            "https://media.mulf.wtf/collection-img.png",
            "https://mulf.wtf"
        );
        
        console.log("AP1155 Constructor args (hex):");
        console.logBytes(constructorArgs);

        vm.stopBroadcast();
    }

}
