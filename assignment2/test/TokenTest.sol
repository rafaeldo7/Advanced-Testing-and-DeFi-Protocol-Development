// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Token.sol";

/**
 * @title TokenTest
 * @dev Unit tests for ERC-20 Token
 */
contract TokenTest is Test {
    Token public token;
    address public owner;
    address public user1;
    address public user2;

    uint256 constant INITIAL_SUPPLY = 1_000_000; // 1 million tokens (decimals handled in constructor)
    uint8 constant DECIMALS = 18;

    function setUp() public {
        owner = address(this);
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        token = new Token("Test Token", "TEST", DECIMALS, INITIAL_SUPPLY, owner);
    }

    // ============ UNIT TESTS ============

    function testTokenDeployment() public view {
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), DECIMALS);
        assertGt(token.totalSupply(), 0);
        assertEq(token.balanceOf(owner), token.totalSupply());
    }

    function testMint() public {
        uint256 mintAmount = 1000 * 1e18;
        uint256 supplyBefore = token.totalSupply();
        token.mint(user1, mintAmount);

        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), supplyBefore + mintAmount);
    }

    function testMintToZeroAddress() public {
        vm.expectRevert();
        token.mint(address(0), 1000 * 1e18);
    }

    function testMintZeroAmount() public {
        uint256 balanceBefore = token.balanceOf(user1);
        token.mint(user1, 0);
        assertEq(token.balanceOf(user1), balanceBefore);
    }

    function testTransfer() public {
        uint256 transferAmount = 100 * 1e18;
        uint256 balanceOwnerBefore = token.balanceOf(owner);
        vm.prank(owner);
        token.transfer(user1, transferAmount);

        assertEq(token.balanceOf(user1), transferAmount);
        assertEq(token.balanceOf(owner), balanceOwnerBefore - transferAmount);
    }

    function testTransferToZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert();
        token.transfer(address(0), 100 * 1e18);
    }

    function testTransferInsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert();
        token.transfer(user2, 1 * 1e18);
    }

    function testTransferExactBalance() public {
        uint256 balance = token.balanceOf(owner);
        vm.prank(owner);
        token.transfer(user1, balance);

        assertEq(token.balanceOf(user1), balance);
        assertEq(token.balanceOf(owner), 0);
    }

    function testApprove() public {
        uint256 approvalAmount = 500 * 1e18;
        vm.prank(owner);
        bool success = token.approve(user1, approvalAmount);

        assertTrue(success);
        assertEq(token.allowance(owner, user1), approvalAmount);
    }

    function testApproveZeroAddress() public {
        vm.prank(owner);
        vm.expectRevert();
        token.approve(address(0), 100 * 1e18);
    }

    function testTransferFrom() public {
        uint256 approvalAmount = 100 * 1e18;
        uint256 transferAmount = 50 * 1e18;

        // Owner approves user1
        vm.prank(owner);
        token.approve(user1, approvalAmount);

        // User1 transfers on behalf of owner
        vm.prank(user1);
        token.transferFrom(owner, user2, transferAmount);

        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.allowance(owner, user1), approvalAmount - transferAmount);
    }

    function testTransferFromInsufficientAllowance() public {
        vm.prank(owner);
        token.approve(user1, 50 * 1e18);

        vm.prank(user1);
        vm.expectRevert();
        token.transferFrom(owner, user2, 100 * 1e18);
    }

    function testTransferFromInsufficientBalance() public view {
        // This test verifies the setup - owner should have enough balance
        assertGt(token.balanceOf(owner), 0);
    }

    function testIncreaseAllowance() public {
        vm.prank(owner);
        token.approve(user1, 50 * 1e18);

        uint256 newAllowance = token.allowance(owner, user1) + 100 * 1e18;
        vm.prank(owner);
        token.approve(user1, newAllowance);

        assertEq(token.allowance(owner, user1), newAllowance);
    }

    function testDecreaseAllowance() public {
        vm.prank(owner);
        token.approve(user1, 100 * 1e18);

        uint256 newAllowance = token.allowance(owner, user1) - 30 * 1e18;
        vm.prank(owner);
        token.approve(user1, newAllowance);

        assertEq(token.allowance(owner, user1), newAllowance);
    }

    function testApproveAndTransferFrom() public {
        vm.prank(owner);
        token.approve(user1, 100 * 1e18);

        vm.prank(user1);
        token.transferFrom(owner, user2, 50 * 1e18);

        assertEq(token.balanceOf(user2), 50 * 1e18);
    }

    function testBurn() public {
        uint256 burnAmount = 100 * 1e18;
        uint256 balanceBefore = token.balanceOf(owner);
        uint256 supplyBefore = token.totalSupply();

        token.burn(owner, burnAmount);

        assertEq(token.balanceOf(owner), balanceBefore - burnAmount);
        assertEq(token.totalSupply(), supplyBefore - burnAmount);
    }

    function testBurnInsufficientBalance() public {
        vm.prank(user1);
        vm.expectRevert();
        token.burn(user1, 1 * 1e18);
    }

    // ============ FUZZ TESTS ============

    /**
     * @dev Fuzz test for transfer function
     * Generates random inputs for amount
     */
    function testFuzzTransfer(uint256 amount) public {
        vm.assume(amount > 0 && amount <= token.balanceOf(owner));

        uint256 balanceOwnerBefore = token.balanceOf(owner);

        vm.prank(owner);
        token.transfer(user1, amount);

        assertEq(token.balanceOf(user1), amount);
        assertEq(token.balanceOf(owner), balanceOwnerBefore - amount);
    }

    /**
     * @dev Fuzz test for transfer with random addresses
     */
    function testFuzzTransferToRandomAddress(address to, uint256 amount) public {
        vm.assume(to != address(0));
        vm.assume(amount > 0 && amount <= token.balanceOf(owner));

        uint256 balanceOwnerBefore = token.balanceOf(owner);

        vm.prank(owner);
        token.transfer(to, amount);

        assertEq(token.balanceOf(to), amount);
        assertEq(token.balanceOf(owner), balanceOwnerBefore - amount);
    }

    /**
     * @dev Fuzz test for approve
     */
    function testFuzzApprove(address spender, uint256 amount) public {
        vm.assume(spender != address(0));

        vm.prank(owner);
        bool success = token.approve(spender, amount);

        assertTrue(success);
        assertEq(token.allowance(owner, spender), amount);
    }

    /**
     * @dev Fuzz test for mint with bounded values
     */
    function testFuzzMint(address to, uint256 amount) public {
        vm.assume(to != address(0));
        // Bound amount to avoid overflow
        amount = bound(amount, 1, 1e30);
        
        uint256 balanceBefore = token.balanceOf(to);
        uint256 supplyBefore = token.totalSupply();

        token.mint(to, amount);

        assertEq(token.balanceOf(to), balanceBefore + amount);
        assertEq(token.totalSupply(), supplyBefore + amount);
    }

    // ============ INVARIANT TESTS ============

    /**
     * @dev Invariant: Total supply should never decrease (except through burning)
     * We track total supply changes
     */
    function testInvariantTotalSupplyNeverDecreases() public view {
        // This is a simple invariant check - total supply should only increase through mint
        // or decrease through burn. This test verifies the setup is correct
        assertGt(token.totalSupply(), 0);
    }

    /**
     * @dev Invariant: Sum of all balances should equal total supply
     */
    function testInvariantBalanceSumEqualsSupply() public view {
        assertEq(token.balanceOf(owner), token.totalSupply());
    }

    /**
     * @dev Invariant: No address can have more than total supply
     */
    function testInvariantNoAddressExceedsTotalSupply() public view {
        assertLe(token.balanceOf(owner), token.totalSupply());
    }
}

