// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./LPToken.sol";
import "./Token.sol";

/**
 * @title AMM
 * @notice Constant Product Automated Market Maker (x * y = k)
 *
 * This contract implements a basic AMM where:
 * - Users can add liquidity and receive LP tokens
 * - Users can remove liquidity by burning LP tokens
 * - Traders can swap one token for another with 0.3% fee
 * - The invariant k = x * y increases with each trade due to fees
 */
contract AMM {
    LPToken public lpToken;
    IERC20 public tokenA;
    IERC20 public tokenB;

    // Fee is 0.3% (30 basis points)
    uint256 public constant FEE = 30; // FEE / 10000 = 0.003 = 0.3%
    uint256 public constant FEE_DENOMINATOR = 10000;

    // Reserve tracking
    uint256 public reserveA;
    uint256 public reserveB;

    // Reentrancy guard
    uint256 private _locked = 1;
    modifier nonReentrant() {
        require(_locked == 1, "ReentrancyGuard: reentrant call");
        _locked = 2;
        _;
        _locked = 1;
    }

    // Events
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event Swap(
        address indexed trader,
        address indexed inputToken,
        uint256 amountIn,
        uint256 amountOut,
        address indexed outputToken
    );

    constructor(address _tokenA, address _tokenB) {
        require(_tokenA != _tokenB, "Tokens must be different");
        require(_tokenA != address(0) && _tokenB != address(0), "Invalid token address");

        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        lpToken = new LPToken();
    }

    /**
     * @notice Initialize the pool with first liquidity
     * @param amountA Amount of token A to deposit
     * @param amountB Amount of token B to deposit
     */
    function addLiquidity(uint256 amountA, uint256 amountB) public {
        require(amountA > 0 && amountB > 0, "Amounts must be positive");

        // Transfer tokens from user
        require(tokenA.transferFrom(msg.sender, address(this), amountA), "TokenA transfer failed");
        require(tokenB.transferFrom(msg.sender, address(this), amountB), "TokenB transfer failed");

        uint256 liquidity;

        if (reserveA == 0 && reserveB == 0) {
            // First liquidity provider - mint LP tokens equal to geometric mean
            liquidity = sqrt(amountA * amountB);
            require(liquidity > 0, "Invalid liquidity amount");
        } else {
            // Calculate liquidity based on existing reserves
            uint256 liquidityA = (amountA * lpToken.totalSupply()) / reserveA;
            uint256 liquidityB = (amountB * lpToken.totalSupply()) / reserveB;
            liquidity = liquidityA < liquidityB ? liquidityA : liquidityB;
        }

        // Update reserves
        reserveA += amountA;
        reserveB += amountB;

        // Mint LP tokens
        lpToken.mint(msg.sender, liquidity);

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    /**
     * @notice Remove liquidity and get back tokens
     * @param liquidity Amount of LP tokens to burn
     * @param minAmountA Minimum amount of token A to receive (slippage protection)
     * @param minAmountB Minimum amount of token B to receive (slippage protection)
     */
    function removeLiquidity(uint256 liquidity, uint256 minAmountA, uint256 minAmountB) public nonReentrant {
        require(liquidity > 0, "Liquidity must be positive");
        require(lpToken.balanceOf(msg.sender) >= liquidity, "Insufficient LP tokens");

        uint256 totalSupply = lpToken.totalSupply();
        uint256 amountA = (liquidity * reserveA) / totalSupply;
        uint256 amountB = (liquidity * reserveB) / totalSupply;

        require(amountA >= minAmountA, "Insufficient tokenA output");
        require(amountB >= minAmountB, "Insufficient tokenB output");

        // Burn LP tokens
        lpToken.burn(msg.sender, liquidity);

        // Update reserves
        reserveA -= amountA;
        reserveB -= amountB;

        // Transfer tokens back
        require(tokenA.transfer(msg.sender, amountA), "TokenA transfer failed");
        require(tokenB.transfer(msg.sender, amountB), "TokenB transfer failed");

        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidity);
    }

    /**
     * @notice Swap tokenA for tokenB
     * @param amountIn Amount of input tokens
     * @param minAmountOut Minimum output amount (slippage protection)
     * @return amountOut Actual output amount
     */
    function swapAForB(uint256 amountIn, uint256 minAmountOut) public nonReentrant returns (uint256 amountOut) {
        require(amountIn > 0, "Amount in must be positive");

        // Calculate output amount
        amountOut = getAmountOut(amountIn, reserveA, reserveB);
        require(amountOut >= minAmountOut, "Insufficient output amount");

        // Transfer input tokens
        require(tokenA.transferFrom(msg.sender, address(this), amountIn), "Input transfer failed");

        // Apply fee (0.3%) - this stays in the pool, increasing k
        uint256 fee = (amountIn * FEE) / FEE_DENOMINATOR;
        uint256 amountInMinusFee = amountIn - fee;

        // Update reserves
        reserveA += amountInMinusFee;
        reserveB -= amountOut;

        // Transfer output tokens
        require(tokenB.transfer(msg.sender, amountOut), "Output transfer failed");

        emit Swap(msg.sender, address(tokenA), amountIn, amountOut, address(tokenB));
    }

    /**
     * @notice Swap tokenB for tokenA
     * @param amountIn Amount of input tokens
     * @param minAmountOut Minimum output amount (slippage protection)
     * @return amountOut Actual output amount
     */
    function swapBForA(uint256 amountIn, uint256 minAmountOut) public nonReentrant returns (uint256 amountOut) {
        require(amountIn > 0, "Amount in must be positive");

        // Calculate output amount
        amountOut = getAmountOut(amountIn, reserveB, reserveA);
        require(amountOut >= minAmountOut, "Insufficient output amount");

        // Transfer input tokens
        require(tokenB.transferFrom(msg.sender, address(this), amountIn), "Input transfer failed");

        // Apply fee (0.3%)
        uint256 fee = (amountIn * FEE) / FEE_DENOMINATOR;
        uint256 amountInMinusFee = amountIn - fee;

        // Update reserves
        reserveB += amountInMinusFee;
        reserveA -= amountOut;

        // Transfer output tokens
        require(tokenA.transfer(msg.sender, amountOut), "Output transfer failed");

        emit Swap(msg.sender, address(tokenB), amountIn, amountOut, address(tokenA));
    }

    /**
     * @notice Calculate output amount using constant product formula
     * @param amountIn Input amount
     * @param reserveIn Input reserve
     * @param reserveOut Output reserve
     * @return Output amount after fee
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        require(amountIn > 0, "Amount in must be positive");
        require(reserveIn > 0 && reserveOut > 0, "Insufficient liquidity");

        // Calculate amount in after fee (0.3%)
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE) / FEE_DENOMINATOR;

        // Constant product formula: y = (x * Y) / (X + x)
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn + amountInWithFee;

        return numerator / denominator;
    }

    /**
     * @notice Get current price of tokenA in terms of tokenB
     */
    function getPriceA() public view returns (uint256) {
        require(reserveA > 0, "No liquidity");
        return (reserveB * 1e18) / reserveA;
    }

    /**
     * @notice Get current price of tokenB in terms of tokenA
     */
    function getPriceB() public view returns (uint256) {
        require(reserveB > 0, "No liquidity");
        return (reserveA * 1e18) / reserveB;
    }

    /**
     * @notice Get current k value (invariant)
     */
    function getK() public view returns (uint256) {
        return reserveA * reserveB;
    }

    /**
     * @notice Square root function
     */
    function sqrt(uint256 x) public pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }
}
