// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity 0.8.30;

import { AP1155 } from "../src/AP1155.sol";
import { APFactory } from "../src/APFactory.sol";
import { Script, console } from "forge-std/Script.sol";

contract APFactoryScript is Script {

    APFactory public apFactory;

    function setUp() public { }

    function run() public {
        apFactory = new APFactory(0xcDad9f233dAFC49E81b3aC1Abef7C8ef8334986A);
        string memory metadata =
            '{"name":"Test NFT #1","description":"A test NFT for the AP1155 contract deployment","image":"https://media.mulf.wtf/testnft-img.png","attributes":[{"trait_type":"Collection","value":"Test Collection"},{"trait_type":"Rarity","value":"Common"}],"external_url":"https://your-website.com","background_color":"000000"}';

        address deployedAP1155 = apFactory.deployNew(
            8e13,
            8e13,
            "Test Collection",
            "TEST",
            "A test collection for the AP1155 contract deployment",
            "https://media.mulf.wtf/collection-img.png",
            "https://mulf.wtf"
        );

        AP1155 new1155 = AP1155(deployedAP1155);

        console.log("Deployed AP1155 address:", deployedAP1155);

        uint256[] memory ids = new uint256[](1);
        ids[0] = 1;
        uint256[] memory amounts = new uint256[](1);
        amounts[0] = 100;

        new1155.mint{ value: 8e13 * 3 }(1, 100, msg.sender, address(0));

        vm.stopBroadcast();
    }

}
