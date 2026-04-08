// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../src/AMM.sol";
import "../src/TokenA.sol";
import "../src/TokenB.sol";
import "forge-std/Test.sol";

contract AMMTest is Test {
    AMM public amm;
    TokenA public tokenA;
    TokenB public tokenB;

    address public user1;
    address public user2;
    address public user3;

    uint256 constant INITIAL_SUPPLY = 1000000e18;
    uint256 constant ADD_LIQUIDITY_A = 100e18;
    uint256 constant ADD_LIQUIDITY_B = 100e18;

    function setUp() public {
        tokenA = new TokenA(INITIAL_SUPPLY);
        tokenB = new TokenB(INITIAL_SUPPLY);

        amm = new AMM(address(tokenA), address(tokenB));

        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        // Give users some tokens
        tokenA.transfer(user1, 10000e18);
        tokenB.transfer(user1, 10000e18);
        tokenA.transfer(user2, 10000e18);
        tokenB.transfer(user2, 10000e18);

        // Approve AMM for all users
        vm.prank(user1);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(user1);
        tokenB.approve(address(amm), type(uint256).max);
        vm.prank(user2);
        tokenA.approve(address(amm), type(uint256).max);
        vm.prank(user2);
        tokenB.approve(address(amm), type(uint256).max);
    }

    // ==================== ADD LIQUIDITY TESTS ====================

    // Test 1: First liquidity provider
    function testAddLiquidityFirstProvider() public {
        vm.prank(user1);
        amm.addLiquidity(ADD_LIQUIDITY_A, ADD_LIQUIDITY_B);

        assertEq(amm.reserveA(), ADD_LIQUIDITY_A);
        assertEq(amm.reserveB(), ADD_LIQUIDITY_B);
        assertTrue(amm.lpToken().balanceOf(user1) > 0);
    }

    // Test 2: Add liquidity as second provider
    function testAddLiquiditySecondProvider() public {
        // First provider
        vm.prank(user1);
        amm.addLiquidity(ADD_LIQUIDITY_A, ADD_LIQUIDITY_B);

        uint256 firstProviderLP = amm.lpToken().balanceOf(user1);

        // Second provider adds same ratio
        vm.prank(user2);
        amm.addLiquidity(ADD_LIQUIDITY_A, ADD_LIQUIDITY_B);

        uint256 secondProviderLP = amm.lpToken().balanceOf(user2);

        // Both should have equal LP tokens
        assertEq(firstProviderLP, secondProviderLP);
    }

    // Test 3: Add liquidity with different amounts (same ratio)
    function testAddLiquidityDifferentAmounts() public {
        vm.prank(user1);
        amm.addLiquidity(100e18, 100e18);

        vm.prank(user2);
        amm.addLiquidity(50e18, 50e18);

        uint256 lp1 = amm.lpToken().balanceOf(user1);
        uint256 lp2 = amm.lpToken().balanceOf(user2);

        assertEq(lp1, lp2 * 2);
    }

    // Test 4: Add liquidity with zero amount should fail
    function testAddLiquidityZeroAmount() public {
        vm.prank(user1);
        vm.expectRevert();
        amm.addLiquidity(0, 100e18);
    }

    // Test 5: Add liquidity with wrong ratio
    function testAddLiquidityWrongRatio() public {
        vm.prank(user1);
        amm.addLiquidity(100e18, 100e18);

        // This should work but with different ratio
        vm.prank(user2);
        amm.addLiquidity(200e18, 100e18);

        // Should succeed but LP tokens will be limited by the smaller ratio
        assertTrue(amm.lpToken().balanceOf(user2) > 0);
    }

    // ==================== REMOVE LIQUIDITY TESTS ====================

    // Test 6: Remove partial liquidity
    function testRemoveLiquidityPartial() public {
        vm.prank(user1);
        amm.addLiquidity(100e18, 100e18);

        uint256 lpBalance = amm.lpToken().balanceOf(user1);

        // Remove 50% of liquidity
        vm.prank(user1);
        amm.removeLiquidity(lpBalance / 2, 0, 0);

        assertEq(amm.lpToken().balanceOf(user1), lpBalance / 2);
    }

    // Test 7: Remove full liquidity
    function testRemoveLiquidityFull() public {
        vm.prank(user1);
        amm.addLiquidity(100e18, 100e18);

        uint256 lpBalance = amm.lpToken().balanceOf(user1);

        vm.prank(user1);
        amm.removeLiquidity(lpBalance, 0, 0);

        assertEq(amm.lpToken().balanceOf(user1), 0);
    }

    // Test 8: Remove liquidity with slippage protection
    function testRemoveLiquiditySlippageProtection() public {
        vm.prank(user1);
        amm.addLiquidity(100e18, 100e18);

        uint256 lpBalance = amm.lpToken().balanceOf(user1);

        // Try to remove with too high minimum (more than what we get) - should fail
        vm.prank(user1);
        vm.expectRevert();
        // Requesting 200e18 of each token when only 100e18 available
        amm.removeLiquidity(lpBalance, 200e18, 200e18);
    }

    // ==================== SWAP TESTS ====================

    // Test 9: Swap A for B
    function testSwapAForB() public {
        // Add liquidity
        vm.prank(user1);
        amm.addLiquidity(1000e18, 1000e18);

        uint256 balanceBBefore = tokenB.balanceOf(user2);

        // Swap
        vm.prank(user2);
        amm.swapAForB(10e18, 0);

        uint256 balanceBAfter = tokenB.balanceOf(user2);
        assertTrue(balanceBAfter > balanceBBefore);
    }

    // Test 10: Swap B for A
    function testSwapBForA() public {
        vm.prank(user1);
        amm.addLiquidity(1000e18, 1000e18);

        uint256 balanceABefore = tokenA.balanceOf(user2);

        vm.prank(user2);
        amm.swapBForA(10e18, 0);

        uint256 balanceAAfter = tokenA.balanceOf(user2);
        assertTrue(balanceAAfter > balanceABefore);
    }

    // Test 11: Swap with slippage protection
    function testSwapSlippageProtection() public {
        vm.prank(user1);
        amm.addLiquidity(1000e18, 1000e18);

        // Get expected output
        uint256 expectedOut = amm.getAmountOut(10e18, 1000e18, 1000e18);

        // Try with minimum higher than expected - should fail
        vm.prank(user2);
        vm.expectRevert();
        amm.swapAForB(10e18, expectedOut + 1);
    }

    // Test 12: Swap zero amount should fail
    function testSwapZeroAmount() public {
        vm.prank(user1);
        amm.addLiquidity(100e18, 100e18);

        vm.prank(user2);
        vm.expectRevert();
        amm.swapAForB(0, 0);
    }

    // ==================== INVARIANT TESTS ====================

    // Test 13: K increases after swap (due to fees)
    function testKIncreasesAfterSwap() public {
        vm.prank(user1);
        amm.addLiquidity(1000e18, 1000e18);

        uint256 kBefore = amm.getK();

        vm.prank(user2);
        amm.swapAForB(10e18, 0);

        uint256 kAfter = amm.getK();

        assertTrue(kAfter > kBefore, "K should increase after swap due to fees");
    }

    // Test 14: K increases after adding liquidity (pool grows)
    function testKIncreasesAfterAddingLiquidity() public {
        vm.prank(user1);
        amm.addLiquidity(100e18, 100e18);

        uint256 k1 = amm.getK();

        vm.prank(user2);
        amm.addLiquidity(50e18, 50e18);

        uint256 k2 = amm.getK();

        // K increases after adding liquidity
        assertTrue(k2 > k1, "K should increase after adding liquidity");
    }

    // Test 15: Price impact on large swap
    function testPriceImpact() public {
        vm.prank(user1);
        amm.addLiquidity(10000e18, 10000e18);

        // Small swap
        uint256 smallOut = amm.getAmountOut(1e18, 10000e18, 10000e18);

        // Large swap (10% of pool)
        uint256 largeOut = amm.getAmountOut(1000e18, 10000e18, 10000e18);

        // Price per token should be lower for large swap
        uint256 smallPricePerToken = smallOut * 1e18 / 1e18;
        uint256 largePricePerToken = largeOut * 1e18 / 1000e18;

        assertTrue(largePricePerToken < smallPricePerToken, "Large swap should have worse price");
    }

    // ==================== EDGE CASES ====================

    // Test 16: Multiple swaps
    function testMultipleSwaps() public {
        vm.prank(user1);
        amm.addLiquidity(1000e18, 1000e18);

        for (uint256 i = 0; i < 5; i++) {
            vm.prank(user2);
            amm.swapAForB(1e18, 0);
        }

        assertTrue(amm.reserveA() > 1000e18);
    }

    // Test 17: Swap depletes one side
    function testSwapDepletesOneSide() public {
        vm.prank(user1);
        amm.addLiquidity(100e18, 100e18);

        // Large swap that significantly changes reserves
        vm.prank(user2);
        amm.swapAForB(50e18, 0);

        // Both reserves should still be positive
        assertTrue(amm.reserveA() > 0);
        assertTrue(amm.reserveB() > 0);
    }

    // Test 18: Get price functions
    function testGetPrice() public {
        vm.prank(user1);
        amm.addLiquidity(100e18, 200e18);

        uint256 priceA = amm.getPriceA();
        uint256 priceB = amm.getPriceB();

        // PriceA should be 2 (200/100), PriceB should be 0.5 (100/200)
        assertEq(priceA, 2e18);
        assertEq(priceB, 5e17);
    }

    // ==================== FUZZ TESTS ====================

    // Fuzz test: Swap with random amount
    function testFuzzSwapAForB(uint256 amountIn) public {
        amountIn = bound(amountIn, 1e18, 100e18);

        vm.prank(user1);
        amm.addLiquidity(1000e18, 1000e18);

        uint256 balanceBBefore = tokenB.balanceOf(user2);

        vm.prank(user2);
        amm.swapAForB(amountIn, 0);

        uint256 balanceBAfter = tokenB.balanceOf(user2);
        assertTrue(balanceBAfter > balanceBBefore);
    }

    // Fuzz test: Add liquidity with random amounts
    function testFuzzAddLiquidity(uint256 amountA, uint256 amountB) public {
        amountA = bound(amountA, 1e18, 1000e18);
        amountB = bound(amountB, 1e18, 1000e18);

        vm.prank(user1);
        amm.addLiquidity(amountA, amountB);

        assertEq(amm.reserveA(), amountA);
        assertEq(amm.reserveB(), amountB);
    }

    // ==================== ADDITIONAL BRANCH COVERAGE TESTS ====================

    // Test: Constructor - same token addresses should fail
    function testConstructorRejectsSameToken() public {
        TokenA sameToken = new TokenA(INITIAL_SUPPLY);
        vm.expectRevert();
        new AMM(address(sameToken), address(sameToken));
    }

    // Test: Constructor - zero address should fail
    function testConstructorRejectsZeroAddress() public {
        vm.expectRevert();
        new AMM(address(0), address(tokenB));
    }

    // Test: Constructor - zero address for tokenB should fail
    function testConstructorRejectsZeroAddressB() public {
        vm.expectRevert();
        new AMM(address(tokenA), address(0));
    }

    // Test: Remove liquidity slippage protection - tokenB side
    function testRemoveLiquiditySlippageProtectionTokenB() public {
        vm.prank(user1);
        amm.addLiquidity(100e18, 100e18);

        uint256 lpBalance = amm.lpToken().balanceOf(user1);

        vm.prank(user1);
        vm.expectRevert();
        amm.removeLiquidity(lpBalance, 0, 200e18); // Require more tokenB than available
    }

    // Test: getAmountOut with zero amountIn should fail
    function testGetAmountOutZeroAmountIn() public {
        vm.prank(user1);
        amm.addLiquidity(100e18, 100e18);

        vm.expectRevert();
        amm.getAmountOut(0, 100e18, 100e18);
    }

    // Test: getAmountOut with zero reserve should fail
    function testGetAmountOutZeroReserve() public {
        vm.expectRevert();
        amm.getAmountOut(10e18, 0, 100e18);
    }

    // Test: getAmountOut with zero output reserve should fail
    function testGetAmountOutZeroOutputReserve() public {
        vm.prank(user1);
        amm.addLiquidity(100e18, 100e18);

        vm.expectRevert();
        amm.getAmountOut(10e18, 100e18, 0);
    }

    // Test: getPriceA with zero reserve should fail
    function testGetPriceAZeroReserve() public {
        vm.expectRevert();
        amm.getPriceA();
    }

    // Test: getPriceB with zero reserve should fail
    function testGetPriceBZeroReserve() public {
        vm.expectRevert();
        amm.getPriceB();
    }

    // Test: Add liquidity - zero amountB should fail (different branch)
    function testAddLiquidityZeroAmountB() public {
        vm.prank(user1);
        vm.expectRevert();
        amm.addLiquidity(100e18, 0);
    }

    // Test: Remove liquidity - zero liquidity should fail
    function testRemoveLiquidityZeroAmount() public {
        vm.prank(user1);
        amm.addLiquidity(100e18, 100e18);

        vm.prank(user1);
        vm.expectRevert();
        amm.removeLiquidity(0, 0, 0);
    }

    // Test: Remove liquidity - insufficient LP tokens
    function testRemoveLiquidityInsufficientLP() public {
        vm.prank(user1);
        amm.addLiquidity(100e18, 100e18);

        vm.prank(user2);
        vm.expectRevert();
        amm.removeLiquidity(100e18, 0, 0);
    }

    // Test: Swap with insufficient output for tokenB
    function testSwapSlippageProtectionTokenB() public {
        vm.prank(user1);
        amm.addLiquidity(1000e18, 1000e18);

        uint256 expectedOut = amm.getAmountOut(10e18, 1000e18, 1000e18);

        vm.prank(user2);
        vm.expectRevert();
        amm.swapBForA(10e18, expectedOut + 1);
    }

    // Test: getAmountOut - verify fee calculation
    function testGetAmountOutFeeCalculation() public {
        vm.prank(user1);
        amm.addLiquidity(1000e18, 1000e18);

        // 10e18 with 0.3% fee = 9.97e18
        // Output = 9.97e18 * 1000e18 / (1000e18 + 9.97e18) ≈ 9.7e18
        uint256 amountOut = amm.getAmountOut(10e18, 1000e18, 1000e18);

        // Should be approximately 9.7e18 (less than input due to fee)
        assertTrue(amountOut < 10e18);
        assertTrue(amountOut > 9e18);
    }

    // Test: Swap - zero reserve after swap should still work
    function testSwapWithSmallReserve() public {
        vm.prank(user1);
        amm.addLiquidity(1e18, 1e18);

        // Very small swap
        vm.prank(user2);
        amm.swapAForB(1e15, 0); // 0.001e18

        assertTrue(amm.reserveA() > 1e18);
    }

    // Test: getK function
    function testGetK() public {
        vm.prank(user1);
        amm.addLiquidity(100e18, 200e18);

        uint256 k = amm.getK();
        assertEq(k, 100e18 * 200e18);
    }

    // Test: getAmountOut with large amount
    function testGetAmountOutLargeAmount() public {
        vm.prank(user1);
        amm.addLiquidity(1000e18, 1000e18);

        // 50% of pool
        uint256 amountOut = amm.getAmountOut(500e18, 1000e18, 1000e18);

        // Should get approximately 333e18 (less than half due to price impact)
        assertTrue(amountOut < 500e18);
        assertTrue(amountOut > 300e18);
    }

    // Test: sqrt function with zero
    function testSqrtZero() public {
        uint256 result = amm.sqrt(0);
        assertEq(result, 0);
    }

    // Test: Add liquidity with very small amounts (tests sqrt edge case)
    function testAddLiquidityVerySmall() public {
        vm.prank(user1);
        // Very small amounts that still give non-zero sqrt
        amm.addLiquidity(1, 1);

        assertTrue(amm.lpToken().totalSupply() > 0);
    }
}
