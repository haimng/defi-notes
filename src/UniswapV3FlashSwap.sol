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

    uint160 internal constant MIN_SQRT_RATIO = 4295128739;
    uint160 internal constant MAX_SQRT_RATIO =
        1461446703485210103287273052203988822378723970342;

    struct FlashSwapData {
        address caller;
        address pool0;
        uint24 fee1;
        address tokenIn;
        address tokenOut;
        uint amountIn;
        bool zeroForOne;
    }
    
    function flashSwap(address pool0, uint24 fee1, address tokenIn, address tokenOut, uint amountIn) external {
        bool zeroForOne = tokenIn < tokenOut;
        uint160 sqrtPriceLimitX96 = zeroForOne ? MIN_SQRT_RATIO + 1 : MAX_SQRT_RATIO - 1;
        bytes memory data = abi.encode(FlashSwapData({
            caller: msg.sender,
            pool0: pool0,
            fee1: fee1,
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            amountIn: amountIn,
            zeroForOne: zeroForOne
        }));

        IUniswapV3Pool(pool0).swap(
            address(this),
            zeroForOne,
            int(amountIn),
            sqrtPriceLimitX96,
            data
        );
    }

    function uniswapV3SwapCallback(
        int amount0,
        int amount1,
        bytes calldata _data
    ) external {
        FlashSwapData memory data = abi.decode(_data, (FlashSwapData));

        require(msg.sender == address(data.pool0), "not authorized");

        console.log("amount0", uint(amount0));
        console.log("amount1", uint(amount1));

        uint amountOut;
        if (data.zeroForOne) {
            amountOut = uint(-amount1);
        } else {
            amountOut = uint(-amount0);
        }

        uint buyBackAmount = _swap(data.tokenOut, data.tokenIn, data.fee1, amountOut);
    
        if (buyBackAmount >= data.amountIn) {
            uint profit = buyBackAmount - data.amountIn;
            IERC20(data.tokenIn).transfer(address(data.pool0), data.amountIn);
            IERC20(data.tokenIn).transfer(data.caller, profit);
        } else {
            uint loss = data.amountIn - buyBackAmount;
            IERC20(data.tokenIn).transferFrom(data.caller, address(this), loss);
            IERC20(data.tokenIn).transfer(address(data.pool0), data.amountIn);
        }
    }

    function _swap(address tokenIn, address tokenOut, uint24 fee, uint amountIn) private returns (uint amountOut) {
        IERC20(tokenIn).approve(address(router), amountIn);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter.ExactInputSingleParams({
            tokenIn: tokenIn,
            tokenOut: tokenOut,
            fee: fee,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: amountIn,
            amountOutMinimum: 0,
            sqrtPriceLimitX96: 0
        });

        amountOut = router.exactInputSingle(params);
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