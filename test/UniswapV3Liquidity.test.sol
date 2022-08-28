// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import "../src/UniswapV3Liquidity.sol";

contract UniswapV3LiquidityTest is Test {
    IWETH  private constant weth = IWETH(WETH);
    IERC20 private constant dai = IERC20(DAI);

    address private constant DAI_WHALE = 0xe81D6f03028107A20DBc83176DA82aE8099E9C42;

    UniswapV3Liquidity private uni = new UniswapV3Liquidity();

    uint constant private DAI_AMOUNT = 1e18;
    uint constant private WETH_AMOUNT = 1e18;

    function setUp() public {
        vm.prank(DAI_WHALE);
        dai.transfer(address(this), DAI_AMOUNT);

        weth.deposit{value: WETH_AMOUNT}();
    }

    function testMintNewPosition() public {
        dai.approve(address(uni), DAI_AMOUNT);
        weth.approve(address(uni), WETH_AMOUNT);

        (uint tokenId, uint liquidity, uint amount0, uint amount1) = uni.mintNewPosition(
            DAI_AMOUNT, WETH_AMOUNT
        );

        console.log("DAI", dai.balanceOf(address(uni)));
        console.log("weth", weth.balanceOf(address(uni)));

        console.log("token id", tokenId);
        console.log("liquidity", liquidity);
        console.log("amount 0", amount0);
        console.log("amount 1", amount1);
    }
}