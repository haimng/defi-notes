// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/console.sol";

// Buy WETH low -> Sell WETH high
// DAI in       -> DAI out        -> DAI profit

// Sell WETH high -> Buy WETH low
// WETH in        -> WETH out     -> WETH profit

contract UniswapV3FlashSwap {
    address private constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;

    IERC20 private constant dai = IERC20(DAI);
    IERC20 private constant weth = IERC20(WETH);

    ISwapRouter constant router =
        ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    // DAI / WETH pool
    IUniswapV3Pool private constant pool =
        IUniswapV3Pool(0xC2e9F25Be6257c210d7Adf0D4Cd6E3E881ba25f8);

    // uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;
    
    function flashSwap(uint wethAmountIn) external {
        bytes memory data = abi.encode(msg.sender, wethAmountIn);

        pool.swap(
            address(this),
            // WETH -> DAI
            false,
            int(wethAmountIn),
            MAX_SQRT_RATIO - 1,
            data
        );
    }

    function uniswapV3SwapCallback(
        int amount0,
        int amount1,
        bytes calldata data
    ) external {
        require(msg.sender == address(pool), "not authorized");

        (address caller, uint wethAmountIn) = abi.decode(data, (address, uint));

        console.log("DAI", uint(-amount0));
        console.log("WETH", uint(amount1));

        uint wethOut = swap(uint(-amount0));
        console.log("WETH out", wethOut);

        if (wethOut >= uint(amount1)) {
            uint profit = wethOut - uint(amount1);
            console.log("profit", profit);
            weth.transfer(address(pool), uint(amount1));
            weth.transfer(caller, profit);
        } else {
            uint loss = uint(amount1) - wethOut;
            console.log("loss", loss);
            weth.transferFrom(caller, address(this), loss);
            weth.transfer(address(pool), uint(amount1));
        }

        // weth.transferFrom(caller, address(pool), uint(amount1));
    }

    function swap(uint amountIn) private returns (uint wethOut) {
        dai.approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params =
        ISwapRouter.ExactInputSingleParams({
                tokenIn: DAI,
                tokenOut: WETH,
                fee: 500,
                recipient: address(this),
                deadline: block.timestamp,
                amountIn: amountIn,
                amountOutMinimum: 0,
                sqrtPriceLimitX96: 0
            });

        wethOut = router.exactInputSingle(params);
    }

}

interface ISwapRouter {
    struct ExactInputSingleParams {
        address tokenIn;
        address tokenOut;
        uint24 fee;
        address recipient;
        uint256 deadline;
        uint256 amountIn;
        uint256 amountOutMinimum;
        uint160 sqrtPriceLimitX96;
    }

    function exactInputSingle(ExactInputSingleParams calldata params)
        external
        payable
        returns (uint256 amountOut);
}

interface IUniswapV3Pool {
    function swap(
        address recipient,
        bool zeroForOne,
        int256 amountSpecified,
        uint160 sqrtPriceLimitX96,
        bytes calldata data
    ) external returns (int256 amount0, int256 amount1);
}

interface IERC20 {
    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount)
        external
        returns (bool);

    function allowance(address owner, address spender)
        external
        view
        returns (uint256);

    function approve(address spender, uint256 amount)
        external
        returns (bool);

    function transferFrom(address sender, address recipient, uint256 amount)
        external
        returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );
}

interface IWETH is IERC20 {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
}