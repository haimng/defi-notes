// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

contract Counter {
    uint public count;

    function inc() external {
        count++;
    }
}

contract ContractTest is Test {
    Counter private counter = new Counter();

    function setUp() public {
        console.log("setup - count", counter.count());
    }

    function testExample1() public {
        counter.inc();
        console.log("test 1 - count", counter.count());
        assertTrue(true);
    }

    function testExample2() public {
        counter.inc();
        console.log("test 2 - count", counter.count());
        assertTrue(true);
    }
}
