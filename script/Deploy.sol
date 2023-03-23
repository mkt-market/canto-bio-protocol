// SPDX-License-Identifier: GPL-3.0-only
pragma solidity >=0.8.0;

import "forge-std/Script.sol";
import "../src/Bio.sol";

contract DeploymentScript is Script {

    function setUp() public {}

    function run() public {
        string memory seedPhrase = vm.readFile(".secret");
        uint256 privateKey = vm.deriveKey(seedPhrase, 0);
        vm.startBroadcast(privateKey);
        Bio bio = new Bio();
        vm.stopBroadcast();
    }
}
