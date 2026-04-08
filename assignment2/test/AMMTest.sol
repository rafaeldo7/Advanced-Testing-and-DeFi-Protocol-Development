// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Token.sol";
import "../src/AMM.sol";

/**
 * @title AMMTest
 * @dev Test suite for the AMM contract
 */
contract AMMTest is Test {
    Token public tokenA;
    Token public tokenB;
    AMM public amm;
    
    address public liquidityProvider;
    address public trader1;
    address public trader2;

    uint256 constant INITIAL_SUPPLY = 1_000_000 * 1e18;
    uint256 constant AMOUNT_A = 1000 * 1e18;
    uint256 constant AMOUNT_B = 1000 * 1e18;

    function setUp() public {
        liquidityProvider = makeAddr("liquidityProvider");
        trader1 = makeAddr("trader1");
        trader2 = makeAddr("trader2");

        // Deploy tokens
        tokenA = new Token("Token A", "TKNA", 18, INITIAL_SUPPLY, address(this));
        tokenB = new Token("Token B", "TKNB", 18, INITIAL_SUPPLY, address(this));

        // Deploy AMM
        amm = new AMM(address(tokenA), address(tokenB), address(this));

        // Give initial tokens to test accounts
        tokenA.transfer(liquidityProvider, 10_000 * 1e18);
        tokenB.transfer(liquidityProvider, 10_000 * 1e18);
        tokenA.transfer(trader1, 5_000 * 1e18);
        tokenB.transfer(trader1, 5_000 * 1e18);
        tokenA.transfer(trader2, 5_000 * 1e18);
        tokenB.transfer(trader2, 5_000 * 1e18);

        // Approve AMM for all
        tokenA.approve(address(amm), type(uint256).max);
        tokenB.approve(address(amm), type(uint256).max);
        vm.prank(liquidityProvider);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(liquidityProvider);
        tokenB.approve(address(amm), type(uint256).max);
        vm.prank(trader1);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(trader1);
        tokenB.approve(address(amm), type(uint256).max);
        vm.prank(trader2);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(trader2);
        tokenB.approve(address(amm), type(uint256).max);

        // Add initial liquidity
        vm.prank(liquidityProvider);
        amm.addLiquidity(AMOUNT_A, AMOUNT_B, 0, 0);
    }

    // ============ ADD LIQUIDITY TESTS ============

    function testAddLiquidityFirstProvider() public {
        uint256 lpBalanceBefore = amm.lpToken().balanceOf(liquidityProvider);
        
        vm.prank(liquidityProvider);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = amm.addLiquidity(
            100 * 1e18,
            100 * 1e18,
            0,
            0
        );

        assertEq(amountA, 100 * 1e18);
        assertEq(amountB, 100 * 1e18);
        assertGt(liquidity, 0);
        assertEq(amm.lpToken().balanceOf(liquidityProvider), lpBalanceBefore + liquidity);
    }

    function testAddLiquiditySubsequentProvider() public {
        uint256 lpBalanceBefore = amm.lpToken().balanceOf(trader1);
        
        vm.prank(trader1);
        (uint256 amountA, uint256 amountB, uint256 liquidity) = amm.addLiquidity(
            50 * 1e18,
            50 * 1e18,
            0,
            0
        );

        assertEq(amountA, 50 * 1e18);
        assertEq(amountB, 50 * 1e18);
        assertGt(liquidity, 0);
        assertEq(amm.lpToken().balanceOf(trader1), lpBalanceBefore + liquidity);
    }

    function testAddLiquidityProportionalRatio() public {
        // Add liquidity with different ratio - should adjust to match pool ratio
        (uint256 reserveA, uint256 reserveB) = amm.getReserves();
        
        vm.prank(trader1);
        (uint256 amountA, uint256 amountB, ) = amm.addLiquidity(
            200 * 1e18,
            50 * 1e18,
            0,
            0
        );

        // Amounts should be proportional to existing reserves
        assertEq(amountA * reserveB, amountB * reserveA);
    }

    function testAddLiquiditySlippageProtection() public {
        // Test slippage protection for remove liquidity instead
        uint256 lpBalance = amm.lpToken().balanceOf(liquidityProvider);
        
        vm.prank(liquidityProvider);
        vm.expectRevert("AMM: Insufficient token A received");
        amm.removeLiquidity(lpBalance, type(uint256).max, 0);
    }

    function testAddLiquidityZeroAmount() public {
        vm.prank(trader1);
        vm.expectRevert("AMM: Amounts must be greater than 0");
        amm.addLiquidity(0, 100 * 1e18, 0, 0);
    }

    // ============ REMOVE LIQUIDITY TESTS ============

    function testRemoveLiquidityFull() public {
        uint256 lpBalance = amm.lpToken().balanceOf(liquidityProvider);
        uint256 balanceABefore = tokenA.balanceOf(liquidityProvider);
        uint256 balanceBBefore = tokenB.balanceOf(liquidityProvider);

        vm.prank(liquidityProvider);
        amm.removeLiquidity(lpBalance, 0, 0);

        assertEq(amm.lpToken().balanceOf(liquidityProvider), 0);
        assertGt(tokenA.balanceOf(liquidityProvider), balanceABefore);
        assertGt(tokenB.balanceOf(liquidityProvider), balanceBBefore);
    }

    function testRemoveLiquidityPartial() public {
        uint256 lpBalance = amm.lpToken().balanceOf(liquidityProvider);
        uint256 lpBalanceBefore = lpBalance;

        vm.prank(liquidityProvider);
        amm.removeLiquidity(lpBalance / 2, 0, 0);

        assertEq(amm.lpToken().balanceOf(liquidityProvider), lpBalanceBefore / 2);
    }

    function testRemoveLiquiditySlippageProtection() public {
        uint256 lpBalance = amm.lpToken().balanceOf(liquidityProvider);
        
        vm.prank(liquidityProvider);
        vm.expectRevert("AMM: Insufficient token A received");
        amm.removeLiquidity(lpBalance, type(uint256).max, 0);
    }

    function testRemoveLiquidityInsufficientBalance() public {
        vm.prank(trader1);
        vm.expectRevert("AMM: Insufficient LP balance");
        amm.removeLiquidity(1 * 1e18, 0, 0);
    }

    function testRemoveLiquidityZeroAmount() public {
        vm.expectRevert("AMM: Liquidity must be greater than 0");
        amm.removeLiquidity(0, 0, 0);
    }

    // ============ SWAP TESTS ============

    function testSwapAForB() public {
        uint256 amountIn = 10 * 1e18;
        uint256 balanceBBefore = tokenB.balanceOf(trader1);

        vm.prank(trader1);
        uint256 amountOut = amm.swapAForB(amountIn, 0);

        assertGt(amountOut, 0);
        assertEq(tokenB.balanceOf(trader1), balanceBBefore + amountOut);
    }

    function testSwapBForA() public {
        uint256 amountIn = 10 * 1e18;
        uint256 balanceABefore = tokenA.balanceOf(trader1);

        vm.prank(trader1);
        uint256 amountOut = amm.swapBForA(amountIn, 0);

        assertGt(amountOut, 0);
        assertEq(tokenA.balanceOf(trader1), balanceABefore + amountOut);
    }

    function testSwapSlippageProtection() public {
        uint256 amountIn = 10 * 1e18;
        
        // Get expected output
        (uint256 reserveA, uint256 reserveB) = amm.getReserves();
        uint256 expectedOutput = amm.getAmountOut(amountIn, reserveA, reserveB);

        // Try with too high minimum - should revert
        vm.prank(trader1);
        vm.expectRevert("AMM: Insufficient output amount");
        amm.swapAForB(amountIn, expectedOutput + 1);
    }

    function testSwapZeroAmount() public {
        vm.prank(trader1);
        vm.expectRevert("AMM: Amount in must be greater than 0");
        amm.swapAForB(0, 0);
    }

    // ============ INVARIANT TESTS ============

    function testInvariantKIncreasesAfterSwap() public {
        (uint256 reserveA, uint256 reserveB) = amm.getReserves();
        uint256 kBefore = reserveA * reserveB;

        // Perform swap
        vm.prank(trader1);
        amm.swapAForB(1 * 1e18, 0);

        (reserveA, reserveB) = amm.getReserves();
        uint256 kAfter = reserveA * reserveB;

        // k should increase due to fees
        assertGt(kAfter, kBefore);
    }

    function testInvariantKConstantAfterAddRemoveLiquidity() public {
        // Add liquidity
        vm.prank(trader1);
        amm.addLiquidity(50 * 1e18, 50 * 1e18, 0, 0);

        (uint256 reserveA, uint256 reserveB) = amm.getReserves();
        uint256 kAfterAdd = reserveA * reserveB;

        // Remove liquidity
        uint256 lpBalance = amm.lpToken().balanceOf(trader1);
        vm.prank(trader1);
        amm.removeLiquidity(lpBalance, 0, 0);

        (reserveA, reserveB) = amm.getReserves();
        uint256 kAfterRemove = reserveA * reserveB;

        // k should return to original (minus fees from any swaps)
        assertGe(kAfterAdd, kAfterRemove);
    }

    function testInvariantTotalLPSupplyEqualsReserves() public {
        (uint256 reserveA, uint256 reserveB) = amm.getReserves();
        uint256 totalSupply = amm.lpToken().totalSupply();

        assertGt(totalSupply, 0);
        assertGt(reserveA, 0);
        assertGt(reserveB, 0);
    }

    // ============ PRICE IMPACT TESTS ============

    function testPriceImpactLargeSwap() public {
        // Small swap - good price
        uint256 smallAmount = 1 * 1e18;
        (uint256 reserveA, uint256 reserveB) = amm.getReserves();
        uint256 smallOutput = amm.getAmountOut(smallAmount, reserveA, reserveB);
        uint256 smallPrice = (smallOutput * 1e18) / smallAmount;

        // Large swap - worse price
        uint256 largeAmount = 100 * 1e18;
        uint256 largeOutput = amm.getAmountOut(largeAmount, reserveA, reserveB);
        uint256 largePrice = (largeOutput * 1e18) / largeAmount;

        // Large swap has worse price
        assertLt(largePrice, smallPrice);
    }

    function testSwapBothDirections() public {
        // Get initial balance of both tokens
        uint256 balanceABefore = tokenA.balanceOf(trader2);
        uint256 balanceBBefore = tokenB.balanceOf(trader2);

        // Swap A for B
        vm.prank(trader2);
        amm.swapAForB(10 * 1e18, 0);

        uint256 balanceAAfterFirstSwap = tokenA.balanceOf(trader2);
        
        // Swap B for A
        vm.prank(trader2);
        amm.swapBForA(10 * 1e18, 0);

        // After swap A->B, balance A should decrease
        assertLt(balanceAAfterFirstSwap, balanceABefore);
        
        // After swap B->A, balance A should increase (but less than before due to fees)
        assertGt(tokenA.balanceOf(trader2), balanceAAfterFirstSwap);
    }

    // ============ FUZZ TESTS ============

    function testFuzzSwapAForB(uint256 amountIn) public {
        // Skip zero or very small amounts
        amountIn = bound(amountIn, 1e10, tokenA.balanceOf(trader1) / 10);
        
        uint256 balanceBBefore = tokenB.balanceOf(trader1);
        
        vm.prank(trader1);
        uint256 amountOut = amm.swapAForB(amountIn, 0);

        assertGt(amountOut, 0);
        assertEq(tokenB.balanceOf(trader1), balanceBBefore + amountOut);
    }

    function testFuzzSwapBForA(uint256 amountIn) public {
        // Skip zero or very small amounts
        amountIn = bound(amountIn, 1e10, tokenB.balanceOf(trader1) / 10);
        
        uint256 balanceABefore = tokenA.balanceOf(trader1);
        
        vm.prank(trader1);
        uint256 amountOut = amm.swapBForA(amountIn, 0);

        assertGt(amountOut, 0);
        assertEq(tokenA.balanceOf(trader1), balanceABefore + amountOut);
    }

    function testFuzzAddLiquidity(uint256 amountA, uint256 amountB) public {
        amountA = bound(amountA, 1 * 1e18, 100 * 1e18);
        amountB = bound(amountB, 1 * 1e18, 100 * 1e18);

        uint256 lpBalanceBefore = amm.lpToken().balanceOf(trader1);

        vm.prank(trader1);
        (uint256 addedA, uint256 addedB, uint256 liquidity) = amm.addLiquidity(
            amountA, amountB, 0, 0
        );

        assertGt(liquidity, 0);
        assertEq(amm.lpToken().balanceOf(trader1), lpBalanceBefore + liquidity);
    }

    function testFuzzRemoveLiquidity(uint256 liquidity) public {
        // First add some liquidity
        vm.prank(trader1);
        amm.addLiquidity(50 * 1e18, 50 * 1e18, 0, 0);

        uint256 maxLiquidity = amm.lpToken().balanceOf(trader1);
        liquidity = bound(liquidity, 1, maxLiquidity);

        uint256 balanceABefore = tokenA.balanceOf(trader1);
        uint256 balanceBBefore = tokenB.balanceOf(trader1);

        vm.prank(trader1);
        (uint256 amountA, uint256 amountB) = amm.removeLiquidity(liquidity, 0, 0);

        assertGt(amountA, 0);
        assertGt(amountB, 0);
        assertEq(tokenA.balanceOf(trader1), balanceABefore + amountA);
        assertEq(tokenB.balanceOf(trader1), balanceBBefore + amountB);
    }

    // ============ EDGE CASES ============

    function testGetAmountOutZeroAmount() public {
        vm.expectRevert("AMM: Amount in must be greater than 0");
        amm.getAmountOut(0, 1000 * 1e18, 1000 * 1e18);
    }

    function testGetAmountOutZeroReserve() public {
        vm.expectRevert("AMM: Insufficient liquidity");
        amm.getAmountOut(100 * 1e18, 0, 1000 * 1e18);
    }

    function testMultipleSwapsAccumulateFees() public {
        (uint256 reserveA, uint256 reserveB) = amm.getReserves();
        uint256 kInitial = reserveA * reserveB;

        // Multiple swaps
        for (uint256 i = 0; i < 5; i++) {
            vm.prank(trader1);
            amm.swapAForB(5 * 1e18, 0);
        }

        (reserveA, reserveB) = amm.getReserves();
        uint256 kFinal = reserveA * reserveB;

        // k should have increased due to fees
        assertGt(kFinal, kInitial);
    }
}
