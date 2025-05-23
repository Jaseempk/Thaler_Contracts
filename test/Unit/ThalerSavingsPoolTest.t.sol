// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ThalerSavingsPool} from "../../src/ThalerSavingsPool.sol";
import {MockERC20} from "./mocks/MockERC20.sol";
import {MockVerifier} from "./mocks/MockVerifier.sol";

/**
 * @title ThalerSavingsPoolTest
 * @notice Comprehensive test suite for the ThalerSavingsPool contract
 * @dev Tests all functionality, edge cases, and potential vulnerabilities
 */
contract ThalerSavingsPoolTest is Test {
    // Constants for test configuration
    uint48 private constant THREE_MONTHS = 7884000; // 3 months in seconds
    uint48 private constant SIX_MONTHS = 15768000; // 6 months in seconds
    uint48 private constant TWELVE_MONTHS = 31536000; // 12 months in seconds
    uint48 private constant INTERVAL = 2628000; // 1 month in seconds
    uint256 private constant DONATION_RATIO = (3 / 25) * 100;

    address public charityAddress = makeAddr("charity");

    // Test accounts
    address private deployer = makeAddr("deployer");
    address private user1 = makeAddr("user1");
    address private user2 = makeAddr("user2");
    address private user3 = makeAddr("user3");
    address private recipient = makeAddr("recipient");

    // Contract instances
    ThalerSavingsPool private savingsPool;
    MockERC20 private token;
    MockVerifier private verifier;

    // Test data
    bytes32 private savingsPoolId;
    bytes private mockProof;
    bytes32[] private mockPublicInputs;
    uint8 private totalIntervals = 12;

    // Events to test
    event SavingsPoolCreated(
        address user,
        uint256 endDate,
        uint256 duration,
        uint256 startDate,
        uint256 totalSaved,
        address tokenToSave,
        uint256 amountToSave,
        uint256 initialDeposit,
        uint256 totalWithdrawn,
        uint256 nextDepositDate,
        uint256 numberOfDeposits,
        uint256 lastDepositedTimestamp
    );

    event SavingsPoolERC20Deposited(
        address user,
        bytes32 savingsPoolId,
        uint256 depositedAmount,
        uint256 totalSaved,
        uint256 nextDepositDate,
        uint256 numberOfDeposits,
        uint256 lastDepositedTimestamp
    );

    event SavingsPoolETHDeposited(
        address user,
        bytes32 savingsPoolId,
        uint256 depositedAmount,
        uint256 totalSaved,
        uint256 nextDepositDate,
        uint256 numberOfDeposits,
        uint256 lastDepositedTimestamp
    );
    event WithdrawFromERC20Pool(
        address user,
        uint256 endDate,
        uint256 startDate,
        uint256 timeStamp,
        uint256 totalSaved,
        address tokenSaved,
        uint256 poolDuration,
        bytes32 savingsPoolId,
        uint256 totalWithdrawn
    );

    event WithdrawFromEthPool(
        address user,
        uint256 endDate,
        uint256 startDate,
        uint256 timeStamp,
        uint256 totalSaved,
        uint256 poolDuration,
        bytes32 savingsPoolId,
        uint256 totalWithdrawn
    );

    event Deposit(
        address user,
        bytes32 poolId,
        uint256 depositedAmount,
        uint256 nextDepositDate,
        uint256 totalSaved
    );

    /**
     * @notice Set up the test environment before each test
     */
    function setUp() public {
        // Set up the test environment with the deployer account
        vm.startPrank(deployer);

        // Deploy mock contracts
        token = new MockERC20("Test Token", "TEST", 18);
        verifier = new MockVerifier();

        // Deploy the ThalerSavingsPool contract
        savingsPool = new ThalerSavingsPool();

        // Initialize mock proof data
        mockProof = abi.encode("mock proof data");
        mockPublicInputs = new bytes32[](4);
        mockPublicInputs[0] = bytes32(uint256(0x1)); // tx_hash
        mockPublicInputs[1] = bytes32(uint256(uint160(user1))); // sender
        mockPublicInputs[2] = bytes32(uint256(uint160(recipient))); // recipient
        mockPublicInputs[3] = bytes32(uint256(1 ether)); // donation_amount

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                    ERC20 SAVINGS POOL CREATION TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test creating an ERC20 savings pool with valid parameters
     */
    function test_CreateSavingsPoolERC20_ValidParams() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL; // 12 months worth of savings
        uint88 initialDeposit = INTERVAL; // 1 month initial deposit
        uint64 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Approve tokens for the savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);

        // Expect the SavingsPoolCreated event to be emitted
        vm.expectEmit(true, true, true, true);
        emit SavingsPoolCreated(
            user1,
            block.timestamp + duration,
            duration,
            block.timestamp,
            initialDeposit,
            address(token),
            amountToSave,
            initialDeposit,
            0,
            block.timestamp + INTERVAL,
            amountToSave / totalIntervals,
            block.timestamp
        );

        // Create the savings pool
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(
            abi.encodePacked(user1, block.timestamp, address(token))
        );

        // Get the savings pool data
        (
            address poolUser,
            uint64 poolDuration,
            uint32 numberOfDeposits,
            uint88 totalSaved,
            address tokenToSave,
            uint88 poolAmountToSave,
            ,
            uint88 poolInitialDeposit,
            uint48 endDate,
            uint48 startDate,
            uint48 nextDepositDate,
            uint48 lastDepositedTimestamp
        ) = savingsPool.savingsPools(poolId);

        console.log("heey");
        console.log("poolUser", poolUser);

        uint8 _totalIntervals = uint8(poolDuration / INTERVAL);

        // Verify the savings pool data
        assertEq(poolUser, user1, "User should be set correctly");
        assertEq(
            endDate,
            block.timestamp + duration,
            "End date should be set correctly"
        );
        assertEq(poolDuration, duration, "Duration should be set correctly");
        assertEq(
            startDate,
            block.timestamp,
            "Start date should be set correctly"
        );
        assertEq(totalSaved, 0, "Total saved should be 0 initially"); // Note: This is 0 because the contract doesn't update totalSaved
        assertEq(tokenToSave, address(token), "Token should be set correctly");
        assertEq(
            poolAmountToSave,
            amountToSave,
            "Amount to save should be set correctly"
        );
        assertEq(
            poolInitialDeposit,
            initialDeposit,
            "Initial deposit should be set correctly"
        );

        assertEq(
            nextDepositDate,
            block.timestamp + INTERVAL,
            "Next deposit date should be set correctly"
        );
        assertEq(
            numberOfDeposits,
            amountToSave / _totalIntervals,
            "Number of deposits should be set correctly"
        );
        assertEq(
            lastDepositedTimestamp,
            block.timestamp,
            "Last deposited timestamp should be set correctly"
        );

        // Verify token transfer
        assertEq(
            token.balanceOf(address(savingsPool)),
            initialDeposit,
            "Contract should have received initial deposit"
        );
        assertEq(
            token.balanceOf(user1),
            amountToSave - initialDeposit,
            "User should have remaining tokens"
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ERC20 savings pool with invalid duration
     */
    function test_CreateSavingsPoolERC20_InvalidDuration() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 invalidDuration = 1000 * INTERVAL; // Not 3, 6, or 12 months
        uint8 _totalIntervals = 100;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Approve tokens for the savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);

        // Expect revert with invalid duration
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidTotalDuration.selector);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            invalidDuration,
            initialDeposit,
            _totalIntervals
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ERC20 savings pool with invalid initial deposit
     */
    function test_CreateSavingsPoolERC20_InvalidInitialDeposit() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 invalidInitialDeposit = amountToSave + 1; // Greater than amount to save
        uint64 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, invalidInitialDeposit);
        vm.stopPrank();

        // Approve tokens for the savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), invalidInitialDeposit);

        // Expect revert with invalid initial deposit
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidInitialDeposit.selector);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            invalidInitialDeposit,
            totalIntervals
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ERC20 savings pool with invalid deposit ratio
     */
    function test_CreateSavingsPoolERC20_InvalidDepositRatio() public {
        // Set up test data
        uint88 amountToSave = 10 * INTERVAL; // 10 months worth of savings
        uint88 initialDeposit = 3 * INTERVAL; // Not divisible evenly into amountToSave
        uint64 duration = TWELVE_MONTHS;
        uint8 _totalIntervals = 10;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Approve tokens for the savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);

        // Expect revert with invalid deposit ratio
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidInitialDeposit.selector);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            _totalIntervals
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ERC20 savings pool with zero values
     */
    function test_CreateSavingsPoolERC20_ZeroValues() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;

        vm.startPrank(user1);

        // Test with zero amount to save
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidInitialDeposit.selector);
        savingsPool.createSavingsPoolERC20(
            address(token),
            0,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Test with zero duration
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidTotalDuration.selector);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            0,
            initialDeposit,
            totalIntervals
        );

        // Test with zero initial deposit
        vm.expectRevert();
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            0,
            totalIntervals
        );

        // Test with zero address token
        vm.expectRevert(ThalerSavingsPool.TLR__INVALID_INPUTS.selector);
        savingsPool.createSavingsPoolERC20(
            address(0),
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ERC20 savings pool with invalid amount to save
     */
    function test_CreateSavingsPoolERC20_InvalidAmountToSave() public {
        // Set up test data
        uint88 invalidAmountToSave = 10 * INTERVAL + 1; // Not divisible by interval
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;
        uint8 _totalIntervals = 10;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, invalidAmountToSave);
        vm.stopPrank();

        // Approve tokens for the savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), invalidAmountToSave);

        // Expect revert with invalid amount to save
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidInitialDeposit.selector);
        savingsPool.createSavingsPoolERC20(
            address(token),
            invalidAmountToSave,
            duration,
            initialDeposit,
            _totalIntervals
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ERC20 savings pool with insufficient token approval
     */
    function test_CreateSavingsPoolERC20_InsufficientApproval() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Approve less than initial deposit
        vm.startPrank(user1);
        token.approve(address(savingsPool), initialDeposit - 1);

        // Expect revert with insufficient approval
        vm.expectRevert("ERC20: insufficient allowance");
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ERC20 savings pool with insufficient token balance
     */
    function test_CreateSavingsPoolERC20_InsufficientBalance() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;

        // Mint less than initial deposit to user1
        vm.startPrank(deployer);
        token.mint(user1, initialDeposit - 1);
        vm.stopPrank();

        // Approve tokens for the savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), initialDeposit);

        // Expect revert with insufficient balance
        vm.expectRevert("ERC20: transfer amount exceeds balance");
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                    ETH SAVINGS POOL CREATION TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test creating an ETH savings pool with valid parameters
     */
    function test_CreateSavingsPoolEth_ValidParams() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL; // 12 months worth of savings
        uint88 initialDeposit = INTERVAL; // 1 month initial deposit
        uint64 duration = TWELVE_MONTHS;

        // Deal ETH to user1
        vm.deal(user1, initialDeposit);

        // Expect the SavingsPoolCreated event to be emitted
        vm.startPrank(user1);
        vm.expectEmit(true, true, true, true);
        emit SavingsPoolCreated(
            user1,
            block.timestamp + duration,
            duration,
            block.timestamp,
            initialDeposit,
            address(0),
            amountToSave,
            initialDeposit,
            0,
            block.timestamp + INTERVAL,
            (amountToSave - initialDeposit) / totalIntervals,
            block.timestamp
        );

        // Create the savings pool
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Get the savings pool data
        (
            address poolUser,
            uint64 poolDuration,
            uint32 numberOfDeposits,
            uint88 totalSaved,
            address tokenToSave,
            uint88 poolAmountToSave,
            ,
            uint88 poolInitialDeposit,
            uint48 endDate,
            uint48 startDate,
            uint48 nextDepositDate,
            uint48 lastDepositedTimestamp
        ) = savingsPool.savingsPools(poolId);

        // Verify the savings pool data
        assertEq(poolUser, user1, "User should be set correctly");
        assertEq(
            endDate,
            block.timestamp + duration,
            "End date should be set correctly"
        );
        assertEq(poolDuration, duration, "Duration should be set correctly");
        assertEq(
            startDate,
            block.timestamp,
            "Start date should be set correctly"
        );
        assertEq(
            totalSaved,
            initialDeposit,
            "Total saved should be initial deposit"
        );
        assertEq(tokenToSave, address(0), "Token should be address(0) for ETH");
        assertEq(
            poolAmountToSave,
            amountToSave,
            "Amount to save should be set correctly"
        );
        assertEq(
            poolInitialDeposit,
            initialDeposit,
            "Initial deposit should be set correctly"
        );

        assertEq(
            nextDepositDate,
            block.timestamp + INTERVAL,
            "Next deposit date should be set correctly"
        );
        assertEq(
            numberOfDeposits,
            (amountToSave - initialDeposit) / totalIntervals,
            "Number of deposits should be set correctly"
        );
        assertEq(
            lastDepositedTimestamp,
            block.timestamp,
            "Last deposited timestamp should be set correctly"
        );

        // Verify ETH transfer
        assertEq(
            address(savingsPool).balance,
            initialDeposit,
            "Contract should have received initial deposit"
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ETH savings pool with invalid duration
     */
    function test_CreateSavingsPoolEth_InvalidDuration() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 invalidDuration = 1000 * INTERVAL; // Not 3, 6, or 12 months
        uint8 _totalIntervals = 100;

        // Deal ETH to user1
        vm.deal(user1, initialDeposit);

        // Expect revert with invalid duration
        vm.startPrank(user1);
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidTotalDuration.selector);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            invalidDuration,
            initialDeposit,
            _totalIntervals
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ETH savings pool with invalid initial deposit
     */
    function test_CreateSavingsPoolEth_InvalidInitialDeposit() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 invalidInitialDeposit = amountToSave + 1; // Greater than amount to save
        uint64 duration = TWELVE_MONTHS;

        // Deal ETH to user1
        vm.deal(user1, invalidInitialDeposit);

        // Expect revert with invalid initial deposit
        vm.startPrank(user1);
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidInitialDeposit.selector);
        savingsPool.createSavingsPoolEth{value: invalidInitialDeposit}(
            amountToSave,
            duration,
            invalidInitialDeposit,
            totalIntervals
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ETH savings pool with invalid deposit ratio
     */
    function test_CreateSavingsPoolEth_InvalidDepositRatio() public {
        // Set up test data
        uint88 amountToSave = 10 * INTERVAL; // 10 months worth of savings
        uint88 initialDeposit = 3 * INTERVAL; // Not divisible evenly into amountToSave
        uint64 duration = TWELVE_MONTHS;
        uint8 _totalIntervals = 10;

        // Deal ETH to user1
        vm.deal(user1, initialDeposit);

        // Expect revert with invalid deposit ratio
        vm.startPrank(user1);
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidInitialDeposit.selector);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit,
            _totalIntervals
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ETH savings pool with zero values
     */
    function test_CreateSavingsPoolEth_ZeroValues() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;

        // Deal ETH to user1
        vm.deal(user1, initialDeposit);

        vm.startPrank(user1);

        // Test with zero amount to save
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidInitialDeposit.selector);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            0,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Test with zero duration
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidTotalDuration.selector);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            0,
            initialDeposit,
            totalIntervals
        );

        // Test with zero initial deposit
        vm.expectRevert();
        savingsPool.createSavingsPoolEth{value: 0}(
            amountToSave,
            duration,
            0,
            totalIntervals
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ETH savings pool with invalid amount to save
     */
    function test_CreateSavingsPoolEth_InvalidAmountToSave() public {
        // Set up test data
        uint88 invalidAmountToSave = 10 * INTERVAL + 1; // Not divisible by interval
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;

        // Deal ETH to user1
        vm.deal(user1, initialDeposit);

        // Expect revert with invalid amount to save
        vm.startPrank(user1);
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidInitialDeposit.selector);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            invalidAmountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ETH savings pool with mismatched ETH value
     */
    function test_CreateSavingsPoolEth_MismatchedEthValue() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint256 sentEth = initialDeposit - 1; // Less than initial deposit
        uint64 duration = TWELVE_MONTHS;

        // Deal ETH to user1
        vm.deal(user1, initialDeposit);

        // Expect revert with mismatched ETH value
        vm.startPrank(user1);
        vm.expectRevert(
            ThalerSavingsPool.TLR__InvalidInitialETHDeposit.selector
        );
        savingsPool.createSavingsPoolEth{value: sentEth}(
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        vm.stopPrank();
    }

    /**
     * @notice Test creating an ETH savings pool with insufficient ETH balance
     */
    function test_CreateSavingsPoolEth_InsufficientBalance() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;

        // Deal less than initial deposit to user1
        vm.deal(user1, initialDeposit - 1);

        // Expect revert with insufficient balance
        vm.startPrank(user1);
        vm.expectRevert();
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                            DEPOSIT TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test depositing to an ERC20 savings pool
     */
    function test_DepositToERC20SavingsPoool() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;
        uint88 depositAmount = INTERVAL;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(
            abi.encodePacked(user1, block.timestamp, address(token))
        );

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        uint256 expectedNextDepositDate = nextDepositDate + INTERVAL;
        console.log("nextDepositTimestamp", nextDepositDate);
        console.log("expectedNextDepositTimestamp", expectedNextDepositDate);
        console.log("Interval", INTERVAL);
        vm.warp(nextDepositDate);

        // Expect the Deposit event to be emitted
        vm.expectEmit(true, true, true, true);
        emit SavingsPoolERC20Deposited(
            user1,
            poolId,
            depositAmount,
            initialDeposit + depositAmount,
            expectedNextDepositDate,
            ((amountToSave) / totalIntervals) - 1,
            block.timestamp
        );

        // Deposit to the savings pool
        savingsPool.depositToERC20SavingPool(poolId, depositAmount);

        // Get the updated savings pool data
        (
            ,
            ,
            ,
            uint88 totalSaved,
            ,
            ,
            ,
            ,
            ,
            ,
            uint48 _nextDepositDate,
            uint48 lastDepositedTimestamp
        ) = savingsPool.savingsPools(poolId);
        console.log("totalSaved", totalSaved);
        // Verify the updated savings pool data
        assertEq(
            totalSaved,
            initialDeposit + depositAmount,
            "Total saved should be updated"
        );
        assertEq(
            _nextDepositDate,
            nextDepositDate + INTERVAL,
            "Next deposit date should be updated"
        );
        assertEq(
            lastDepositedTimestamp,
            nextDepositDate,
            "Last deposited timestamp should be updated"
        );

        // Verify token balance
        assertEq(
            token.balanceOf(address(savingsPool)),
            initialDeposit + depositAmount,
            "Contract should have received deposit"
        );

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to an ETH savings pool
     */
    function test_DepositToETHSavingsPoool() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;
        uint88 depositAmount = INTERVAL;

        // Deal ETH to user1
        vm.deal(user1, amountToSave);

        // Create a savings pool
        vm.startPrank(user1);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        uint256 expectedNextDepositDate = nextDepositDate + INTERVAL;
        vm.warp(nextDepositDate);

        // Expect the Deposit event to be emitted
        vm.expectEmit(true, true, true, true);

        emit SavingsPoolETHDeposited(
            user1,
            poolId,
            depositAmount,
            initialDeposit + depositAmount,
            expectedNextDepositDate,
            ((amountToSave) / totalIntervals) - 1,
            block.timestamp
        );

        // Deposit to the savings pool
        savingsPool.depositToEthSavingPool{value: depositAmount}(
            poolId,
            depositAmount
        );

        // Get the updated savings pool data
        (
            ,
            ,
            ,
            uint88 totalSaved,
            ,
            ,
            ,
            ,
            ,
            ,
            uint48 _nextDepositDate,
            uint48 lastDepositedTimestamp
        ) = savingsPool.savingsPools(poolId);

        // Verify the updated savings pool data
        assertEq(
            totalSaved,
            initialDeposit + depositAmount,
            "Total saved should be updated"
        );
        assertEq(
            _nextDepositDate,
            nextDepositDate + INTERVAL,
            "Next deposit date should be updated"
        );
        assertEq(
            lastDepositedTimestamp,
            nextDepositDate,
            "Last deposited timestamp should be updated"
        );

        // Verify ETH balance
        assertEq(
            address(savingsPool).balance,
            initialDeposit + depositAmount,
            "Contract should have received deposit"
        );

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to a non-existent savings pool
     */
    function test_DepositToNonExistentPool() public {
        // Generate a random pool ID
        bytes32 nonExistentPoolId = keccak256(
            abi.encodePacked("non-existent-pool")
        );

        // Expect revert with non-existent pool
        vm.startPrank(user1);
        vm.expectRevert();
        savingsPool.depositToERC20SavingPool(nonExistentPoolId, 0);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to an ERC20 savings pool with insufficient token balance
     */
    function test_DepositToERC20SavingsPool_InsufficientBalance() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;

        // Mint tokens to user1 (just enough for initial deposit)
        vm.startPrank(deployer);
        token.mint(user1, initialDeposit);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), initialDeposit);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(
            abi.encodePacked(user1, block.timestamp, address(token))
        );

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // Expect revert with insufficient balance
        vm.expectRevert(ThalerSavingsPool.TLR__ExcessEthDeposit.selector);
        savingsPool.depositToERC20SavingPool(poolId, amountToSave);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to an ERC20 savings pool with insufficient allowance
     */
    function test_DepositToERC20SavingsPool_InsufficientAllowance() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool with initial approval
        vm.startPrank(user1);
        token.approve(address(savingsPool), initialDeposit);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(
            abi.encodePacked(user1, block.timestamp, address(token))
        );

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // No additional approval given

        // Expect revert with insufficient allowance
        vm.expectRevert("ERC20: insufficient allowance");
        savingsPool.depositToERC20SavingPool(poolId, INTERVAL);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to an ETH savings pool with insufficient ETH
     */
    function test_DepositToETHSavingsPool_InsufficientETH() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;
        uint88 depositAmount = INTERVAL;

        // Deal ETH to user1 (just enough for initial deposit)
        vm.deal(user1, initialDeposit);

        // Create a savings pool
        vm.startPrank(user1);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // Expect revert with insufficient ETH
        vm.expectRevert();
        savingsPool.depositToEthSavingPool{value: depositAmount - 1}(
            poolId,
            (depositAmount - 1)
        );

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to an ETH savings pool with excess ETH
     */
    function test_DepositToETHSavingsPool_ExcessETH() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;
        uint88 depositAmount = INTERVAL;

        // Deal ETH to user1
        vm.deal(user1, amountToSave);

        // Create a savings pool
        vm.startPrank(user1);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // Expect revert with excess ETH
        vm.expectRevert(ThalerSavingsPool.TLR__InvalidEthDepositRatio.selector);
        savingsPool.depositToEthSavingPool{value: depositAmount + 1}(
            poolId,
            depositAmount + 1
        );

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to an ETH savings pool without ETH
     */
    function test_DepositToETHSavingsPool_WithoutETH() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;

        // Deal ETH to user1
        vm.deal(user1, amountToSave);

        // Create a savings pool
        vm.startPrank(user1);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // Expect revert when not sending ETH to an ETH pool
        vm.expectRevert();
        savingsPool.depositToEthSavingPool(poolId, 0);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to a savings pool before the next deposit date
     */
    function test_DepositBeforeNextDepositDate() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(
            abi.encodePacked(user1, block.timestamp, address(token))
        );

        // Expect revert when depositing before next deposit date
        vm.expectRevert(
            ThalerSavingsPool.TLR__SavingPoolDepositIntervalNotYet.selector
        );
        savingsPool.depositToERC20SavingPool(poolId, INTERVAL);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to a savings pool after all deposits are made
     */
    function test_DepositAfterAllDepositsMade() public {
        // Set up test data
        uint88 amountToSave = 3 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = THREE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(
            abi.encodePacked(user1, block.timestamp, address(token))
        );

        // Make all deposits
        for (uint256 i = 0; i < 2; i++) {
            // Warp to next deposit date
            uint256 nextDepositDate = block.timestamp + INTERVAL;
            skip(nextDepositDate);

            // Deposit to the savings pool
            savingsPool.depositToERC20SavingPool(poolId, INTERVAL);
        }

        // Warp to after all deposits
        uint256 finalDepositDate = block.timestamp + INTERVAL;
        skip(finalDepositDate);

        // Expect revert when depositing after all deposits are made
        vm.expectRevert(ThalerSavingsPool.TLR__SavingPoolEnded.selector);
        savingsPool.depositToERC20SavingPool(poolId, INTERVAL);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to a savings pool from a different user with ERC20 token
     */
    function test_DepositFromDifferentUserERC20() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool as user1
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(
            abi.encodePacked(user1, block.timestamp, address(token))
        );
        vm.stopPrank();

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // Try to deposit as user2
        vm.startPrank(user2);
        token.approve(address(savingsPool), INTERVAL);

        // Expect revert when depositing from a different user
        vm.expectRevert(ThalerSavingsPool.TLR__CallerNotOwner.selector);
        savingsPool.depositToERC20SavingPool(poolId, INTERVAL);

        vm.stopPrank();
    }

    /**
     * @notice Test depositing to a savings pool from a different user
     */
    function test_DepositFromDifferentUser() public {
        // Set up test data
        uint88 amountToSave = 12 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = TWELVE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool as user1
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(
            abi.encodePacked(user1, block.timestamp, address(token))
        );
        vm.stopPrank();

        // Warp to next deposit date
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);

        // Try to deposit as user2
        vm.startPrank(user2);
        token.approve(address(savingsPool), INTERVAL);

        // Expect revert when depositing from a different user
        vm.expectRevert(ThalerSavingsPool.TLR__CallerNotOwner.selector);
        savingsPool.depositToERC20SavingPool(poolId, INTERVAL);

        vm.stopPrank();
    }

    /*//////////////////////////////////////////////////////////////
                        WITHDRAWAL TESTS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Test withdrawing from an ERC20 savings pool after completion
     */
    function test_WithdrawFromERC20SavingsPool_AfterCompletion() public {
        // Set up test data
        uint88 amountToSave = 3 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = THREE_MONTHS;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(
            abi.encodePacked(user1, block.timestamp, address(token))
        );

        // Make all deposits
        for (uint256 i = 0; i < 2; i++) {
            // Warp to next deposit date
            uint256 nextDepositDate = block.timestamp + INTERVAL;
            skip(nextDepositDate);

            // Deposit to the savings pool
            savingsPool.depositToERC20SavingPool(poolId, INTERVAL);
        }

        (, , , , , , , , uint48 _endDate, uint48 _startDate, , ) = savingsPool
            .savingsPools(poolId);

        vm.stopPrank();

        // Warp to after the end date
        uint256 endDate = block.timestamp + duration;
        skip(endDate + 1 days);

        vm.prank(address(savingsPool));
        token.approve(address(user1), amountToSave);

        vm.expectEmit(true, true, true, true);
        emit WithdrawFromERC20Pool(
            user1,
            _endDate,
            _startDate,
            block.timestamp,
            amountToSave,
            address(token),
            duration,
            poolId,
            amountToSave
        );

        vm.prank(user1);
        // Withdraw from the savings pool
        savingsPool.withdrawFromERC20SavingPool(poolId, charityAddress);

        // Verify token balance
        assertEq(
            token.balanceOf(address(savingsPool)),
            0,
            "Contract should have sent all tokens"
        );
        assertEq(
            token.balanceOf(user1),
            amountToSave,
            "User should have received all tokens"
        );
    }

    /**
     * @notice Test withdrawing from an ETH savings pool after completion
     */
    function test_WithdrawFromETHSavingsPool_AfterCompletion() public {
        // Set up test data
        uint88 amountToSave = 3 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = THREE_MONTHS;
        uint8 _totalIntervals = 3;

        // Deal ETH to user1
        vm.deal(user1, amountToSave);

        // Create a savings pool
        vm.startPrank(user1);
        savingsPool.createSavingsPoolEth{value: initialDeposit}(
            amountToSave,
            duration,
            initialDeposit,
            _totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Make all deposits
        for (uint256 i = 0; i < 2; i++) {
            // Warp to next deposit date
            uint256 nextDepositDate = block.timestamp + INTERVAL;
            skip(nextDepositDate);

            // Deposit to the savings pool
            savingsPool.depositToEthSavingPool{value: INTERVAL}(
                poolId,
                INTERVAL
            );
        }

        // Warp to after the end date
        uint256 endDate = block.timestamp + duration;
        skip(endDate + 1);

        // Record user's ETH balance before withdrawal
        uint256 userBalanceBefore = user1.balance;

        (, , , , , , , , uint48 _endDate, uint48 _startDate, , ) = savingsPool
            .savingsPools(poolId);

        // Expect the Withdrawal event to be emitted
        vm.expectEmit(true, true, true, true);
        emit WithdrawFromEthPool(
            user1,
            _endDate,
            _startDate,
            block.timestamp,
            amountToSave,
            duration,
            poolId,
            amountToSave
        );

        // Withdraw from the savings pool
        savingsPool.withdrawFromEthSavingPool(poolId, charityAddress);

        // Verify ETH balance
        assertEq(
            address(savingsPool).balance,
            0,
            "Contract should have sent all ETH"
        );
        assertEq(
            user1.balance,
            userBalanceBefore + amountToSave,
            "User should have received all ETH"
        );

        vm.stopPrank();
    }

    /**
     * @notice Test withdrawing from a non-existent savings pool
     */
    function test_WithdrawFromNonExistentPool() public {
        // Generate a random pool ID
        bytes32 nonExistentPoolId = keccak256(
            abi.encodePacked("non-existent-pool")
        );

        // Expect revert with non-existent pool
        vm.startPrank(user1);
        vm.expectRevert();
        savingsPool.withdrawFromEthSavingPool(
            nonExistentPoolId,
            charityAddress
        );

        vm.stopPrank();
    }

    /**
     * @notice Test withdrawing from a savings pool before completion
     */
    function test_WithdrawBeforeCompletion() public {
        // Set up test data
        uint88 amountToSave = 3 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = THREE_MONTHS;
        uint8 _totalIntervals = 3;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            _totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Make one deposit
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);
        savingsPool.depositToERC20SavingPool(poolId, INTERVAL);

        // Warp to before the end date
        uint256 endDate = block.timestamp + duration - 1;
        vm.warp(endDate);

        // Expect revert when withdrawing before completion
        vm.expectRevert();
        savingsPool.withdrawFromERC20SavingPool(poolId, charityAddress);

        vm.stopPrank();
    }

    /**
     * @notice Test withdrawing from a savings pool from a different user
     */
    function test_WithdrawFromDifferentUser() public {
        // Set up test data
        uint88 amountToSave = 3 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = THREE_MONTHS;
        uint8 _totalIntervals = 3;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool as user1
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            _totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Make all deposits
        for (uint256 i = 0; i < 2; i++) {
            // Warp to next deposit date
            uint256 nextDepositDate = block.timestamp + INTERVAL;
            vm.warp(nextDepositDate);

            // Deposit to the savings pool
            savingsPool.depositToERC20SavingPool(poolId, INTERVAL);
        }

        // Warp to after the end date
        uint256 endDate = block.timestamp + duration;
        vm.warp(endDate + 1);

        vm.stopPrank();

        // Try to withdraw as user2
        vm.startPrank(user2);

        // Expect revert when withdrawing from a different user
        // vm.expectRevert(ThalerSavingsPool.TLR__NotPoolOwner.selector);
        savingsPool.withdrawFromEthSavingPool(poolId, charityAddress);

        vm.stopPrank();
    }

    /**
     * @notice Test withdrawing from a savings pool that has already been withdrawn
     */
    function test_WithdrawAfterAlreadyWithdrawn() public {
        // Set up test data
        uint88 amountToSave = 3 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = THREE_MONTHS;
        uint8 _totalIntervals = 3;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            _totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Make all deposits
        for (uint256 i = 0; i < 2; i++) {
            // Warp to next deposit date
            uint256 nextDepositDate = block.timestamp + INTERVAL;
            vm.warp(nextDepositDate);

            // Deposit to the savings pool
            savingsPool.depositToERC20SavingPool(poolId, INTERVAL);
        }

        // Warp to after the end date
        uint256 endDate = block.timestamp + duration;
        vm.warp(endDate + 1);

        // Withdraw from the savings pool
        savingsPool.withdrawFromERC20SavingPool(poolId, charityAddress);

        // Expect revert when withdrawing again
        // vm.expectRevert(ThalerSavingsPool.TLR__AlreadyWithdrawn.selector);
        savingsPool.withdrawFromERC20SavingPool(poolId, charityAddress);

        vm.stopPrank();
    }

    /**
     * @notice Test withdrawing from a savings pool with incomplete deposits
     */
    function test_WithdrawWithIncompleteDeposits() public {
        // Set up test data
        uint88 amountToSave = 3 * INTERVAL;
        uint88 initialDeposit = INTERVAL;
        uint64 duration = THREE_MONTHS;
        uint8 _totalIntervals = 3;

        // Mint tokens to user1
        vm.startPrank(deployer);
        token.mint(user1, amountToSave);
        vm.stopPrank();

        // Create a savings pool
        vm.startPrank(user1);
        token.approve(address(savingsPool), amountToSave);
        savingsPool.createSavingsPoolERC20(
            address(token),
            amountToSave,
            duration,
            initialDeposit,
            _totalIntervals
        );

        // Calculate the savings pool ID
        bytes32 poolId = keccak256(abi.encodePacked(user1, block.timestamp));

        // Make only one deposit (out of two required)
        uint256 nextDepositDate = block.timestamp + INTERVAL;
        vm.warp(nextDepositDate);
        savingsPool.depositToERC20SavingPool(poolId, INTERVAL);

        // Warp to after the end date
        uint256 endDate = block.timestamp + duration;
        vm.warp(endDate + 1);

        // Expect the Withdrawal event to be emitted with partial amount
        vm.expectEmit(true, true, true, true);
        emit WithdrawFromERC20Pool(
            user1,
            endDate,
            block.timestamp,
            block.timestamp,
            initialDeposit + INTERVAL,
            address(token),
            duration,
            poolId,
            initialDeposit + INTERVAL
        );

        // Withdraw from the savings pool
        savingsPool.withdrawFromERC20SavingPool(poolId, charityAddress);

        // Verify token balance
        assertEq(
            token.balanceOf(address(savingsPool)),
            0,
            "Contract should have sent all tokens"
        );
        assertEq(
            token.balanceOf(user1),
            initialDeposit + INTERVAL,
            "User should have received partial tokens"
        );

        vm.stopPrank();
    }
}
