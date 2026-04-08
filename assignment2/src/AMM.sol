// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LPToken.sol";

/**
 * @title AMM
 * @dev Constant Product Automated Market Maker (x * y = k)
 */
contract AMM is Ownable {
    using SafeERC20 for IERC20;

    // ============ EVENTS ============
    event LiquidityAdded(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event LiquidityRemoved(address indexed provider, uint256 amountA, uint256 amountB, uint256 liquidity);
    event Swap(address indexed user, address indexed fromToken, address indexed toToken, uint256 amountIn, uint256 amountOut);

    // ============ STATE VARIABLES ============
    IERC20 public tokenA;
    IERC20 public tokenB;
    LPToken public lpToken;

    uint256 public reserveA;
    uint256 public reserveB;

    // Fee is 0.3% (30 basis points)
    uint256 public constant FEE = 30;
    uint256 public constant FEE_DENOMINATOR = 10000;

    // ============ CONSTRUCTOR ============
    constructor(
        address _tokenA,
        address _tokenB,
        address _owner
    ) Ownable(_owner) {
        require(_tokenA != address(0) && _tokenB != address(0), "AMM: Invalid token addresses");
        require(_tokenA != _tokenB, "AMM: Tokens must be different");

        tokenA = IERC20(_tokenA);
        tokenB = IERC20(_tokenB);
        lpToken = new LPToken("AMM Liquidity Provider", "AMM-LP", _owner);
        lpToken.setAMM(address(this)); // Set AMM address so it can mint/burn LP tokens
    }

    // ============ VIEW FUNCTIONS ============

    /**
     * @dev Get current reserves
     */
    function getReserves() public view returns (uint256, uint256) {
        return (reserveA, reserveB);
    }

    /**
     * @dev Calculate output amount using constant product formula with fee
     * @param amountIn The amount of input tokens
     * @param reserveIn The reserve of input token
     * @param reserveOut The reserve of output token
     * @return amountOut The calculated output amount
     */
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        require(amountIn > 0, "AMM: Amount in must be greater than 0");
        require(reserveIn > 0 && reserveOut > 0, "AMM: Insufficient liquidity");

        // Calculate amount after fee (0.3% fee)
        uint256 amountInWithFee = amountIn * (FEE_DENOMINATOR - FEE) / FEE_DENOMINATOR;

        // Constant product formula: y = (x * Y) / (X + x')
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn + amountInWithFee;

        return numerator / denominator;
    }

    /**
     * @dev Calculate liquidity tokens to mint for adding liquidity
     */
    function _calculateLiquidity(uint256 amountA, uint256 amountB, uint256 totalSupply) internal view returns (uint256) {
        if (totalSupply == 0) {
            // First provider: use geometric mean
            return sqrt(amountA * amountB);
        }
        // Subsequent providers: proportional to existing share
        return min((amountA * totalSupply) / reserveA, (amountB * totalSupply) / reserveB);
    }

    // ============ LIQUIDITY FUNCTIONS ============

    /**
     * @dev Add liquidity to the AMM
     * @param amountADesired Desired amount of token A
     * @param amountBDesired Desired amount of token B
     * @param amountAMin Minimum amount of token A (slippage protection)
     * @param amountBMin Minimum amount of token B (slippage protection)
     * @return amountA Actual amount of token A added
     * @return amountB Actual amount of token B added
     * @return liquidity Amount of LP tokens minted
     */
    function addLiquidity(
        uint256 amountADesired,
        uint256 amountBDesired,
        uint256 amountAMin,
        uint256 amountBMin
    ) external returns (uint256 amountA, uint256 amountB, uint256 liquidity) {
        require(amountADesired > 0 && amountBDesired > 0, "AMM: Amounts must be greater than 0");

        // Transfer tokens from user
        tokenA.safeTransferFrom(msg.sender, address(this), amountADesired);
        tokenB.safeTransferFrom(msg.sender, address(this), amountBDesired);

        uint256 totalSupply = lpToken.totalSupply();

        if (reserveA > 0 && reserveB > 0) {
            // Calculate optimal amounts maintaining ratio
            uint256 amountBOptimal = (amountADesired * reserveB) / reserveA;

            if (amountBOptimal <= amountBDesired) {
                // Adjust amountB
                if (amountBOptimal < amountBMin) {
                    revert("AMM: Insufficient token B");
                }
                amountB = amountBOptimal;
                amountA = amountADesired;
            } else {
                // Adjust amountA
                uint256 amountAOptimal = (amountBDesired * reserveA) / reserveB;
                assert(amountAOptimal <= amountADesired);

                if (amountAOptimal < amountAMin) {
                    revert("AMM: Insufficient token A");
                }
                amountA = amountAOptimal;
                amountB = amountBDesired;
            }

            // Refund excess tokens
            if (amountADesired > amountA) {
                tokenA.safeTransfer(msg.sender, amountADesired - amountA);
            }
            if (amountBDesired > amountB) {
                tokenB.safeTransfer(msg.sender, amountBDesired - amountB);
            }
        } else {
            // First liquidity provider
            amountA = amountADesired;
            amountB = amountBDesired;

            if (amountA < amountAMin || amountB < amountBMin) {
                revert("AMM: Insufficient liquidity amounts");
            }
        }

        // Update reserves
        reserveA += amountA;
        reserveB += amountB;

        // Mint LP tokens
        liquidity = _calculateLiquidity(amountA, amountB, totalSupply);
        require(liquidity > 0, "AMM: Invalid liquidity minted");

        lpToken.mint(msg.sender, liquidity);

        emit LiquidityAdded(msg.sender, amountA, amountB, liquidity);
    }

    /**
     * @dev Remove liquidity from the AMM
     * @param liquidity Amount of LP tokens to burn
     * @param amountAMin Minimum amount of token A to receive (slippage protection)
     * @param amountBMin Minimum amount of token B to receive (slippage protection)
     * @return amountA Amount of token A received
     * @return amountB Amount of token B received
     */
    function removeLiquidity(
        uint256 liquidity,
        uint256 amountAMin,
        uint256 amountBMin
    ) external returns (uint256 amountA, uint256 amountB) {
        require(liquidity > 0, "AMM: Liquidity must be greater than 0");
        require(lpToken.balanceOf(msg.sender) >= liquidity, "AMM: Insufficient LP balance");

        uint256 totalSupply = lpToken.totalSupply();

        // Calculate amounts proportional to liquidity share
        amountA = (liquidity * reserveA) / totalSupply;
        amountB = (liquidity * reserveB) / totalSupply;

        require(amountA >= amountAMin, "AMM: Insufficient token A received");
        require(amountB >= amountBMin, "AMM: Insufficient token B received");

        // Burn LP tokens
        lpToken.burn(msg.sender, liquidity);

        // Update reserves
        reserveA -= amountA;
        reserveB -= amountB;

        // Transfer tokens to user
        tokenA.safeTransfer(msg.sender, amountA);
        tokenB.safeTransfer(msg.sender, amountB);

        emit LiquidityRemoved(msg.sender, amountA, amountB, liquidity);
    }

    // ============ SWAP FUNCTIONS ============

    /**
     * @dev Swap tokenA for tokenB
     * @param amountIn Amount of token A to swap
     * @param amountOutMin Minimum amount of token B to receive (slippage protection)
     * @return amountOut Actual amount of token B received
     */
    function swapAForB(uint256 amountIn, uint256 amountOutMin) external returns (uint256 amountOut) {
        require(amountIn > 0, "AMM: Amount in must be greater than 0");

        // Calculate output amount
        amountOut = getAmountOut(amountIn, reserveA, reserveB);
        require(amountOut >= amountOutMin, "AMM: Insufficient output amount");

        // Transfer input tokens
        tokenA.safeTransferFrom(msg.sender, address(this), amountIn);

        // Update reserves
        reserveA += amountIn;
        reserveB -= amountOut;

        // Transfer output tokens
        tokenB.safeTransfer(msg.sender, amountOut);

        emit Swap(msg.sender, address(tokenA), address(tokenB), amountIn, amountOut);
    }

    /**
     * @dev Swap tokenB for tokenA
     * @param amountIn Amount of token B to swap
     * @param amountOutMin Minimum amount of token A to receive (slippage protection)
     * @return amountOut Actual amount of token A received
     */
    function swapBForA(uint256 amountIn, uint256 amountOutMin) external returns (uint256 amountOut) {
        require(amountIn > 0, "AMM: Amount in must be greater than 0");

        // Calculate output amount
        amountOut = getAmountOut(amountIn, reserveB, reserveA);
        require(amountOut >= amountOutMin, "AMM: Insufficient output amount");

        // Transfer input tokens
        tokenB.safeTransferFrom(msg.sender, address(this), amountIn);

        // Update reserves
        reserveB += amountIn;
        reserveA -= amountOut;

        // Transfer output tokens
        tokenA.safeTransfer(msg.sender, amountOut);

        emit Swap(msg.sender, address(tokenB), address(tokenA), amountIn, amountOut);
    }

    // ============ UTILITY FUNCTIONS ============

    /**
     * @dev Square root function
     */
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    /**
     * @dev Minimum function
     */
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        return a < b ? a : b;
    }
}
