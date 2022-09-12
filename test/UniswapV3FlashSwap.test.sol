// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/UniswapV3FlashSwap.sol";


contract UniswapV3FlashSwapTest is Test {
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IWETH private weth = IWETH(WETH);

    UniswapV3FlashSwap private uni = new UniswapV3FlashSwap();

    function setUp() public {
    }

    function testFlashSwap() public {
        // Approve WETH fee
        uint wethAmountIn = 1e18;
        weth.deposit{value: wethAmountIn}();
        weth.approve(address(uni), wethAmountIn);

        uint balBefore = weth.balanceOf(address(this));
        uni.flashSwap(wethAmountIn);
        uint balAfter = weth.balanceOf(address(this));

        if (balAfter >= balBefore) {
            console.log("WETH profit", balAfter - balBefore);
        } else {
            console.log("WETH loss", balBefore - balAfter);
        }
    }
}