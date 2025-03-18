//SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

contract ThalerSavingsPool {
    error TLR__InValidProof();
    error TLR__INVALID_INPUTS();
    error TLR_InvalidDuration();
    error TLR__SavingPoolEnded();
    error TLR__ExcessEthDeposit();
    error TLR_InvalidTotalDuration();
    error TLR__InvalidDepositAmount();
    error TLR__InvalidInitialDeposit();
    error TLR__InvalidEthDepositRatio();
    error TLR__InvalidEthDepositAmount();
    error TLR__InvalidInitialETHDeposit();
    error TLR__SavingPoolDepositIntervalNotYet();

    uint256 private constant THREE_MONTHS = 7884000;
    uint256 private constant SIX_MONTHS = 15768000;
    uint256 private constant TWELVE_MONTHS = 31536000;
    uint256 public constant INTERVAL = 2628000; //1 month

    IVerifier public verifier;

    struct SavingsPool {
        address user;
        uint256 endDate;
        uint256 duration;
        uint256 startDate;
        uint256 totalSaved;
        address tokenToSave;
        uint256 amountToSave;
        uint256 initialDeposit;
        uint256 totalWithdrawn;
        uint256 nextDepositDate;
        uint256 numberOfDeposits;
        uint256 lastDepositedTimestamp;
    }

    mapping(bytes32 => SavingsPool) public savingsPools;

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

    event SavingsPoolDeposited(
        address user,
        uint256 depositedAmount,
        uint256 totalSaved,
        uint256 nextDepositDate,
        uint256 numberOfDeposits,
        uint256 lastDepositedTimestamp
    );

    constructor(address _verifier) {
        verifier = IVerifier(_verifier);
    }

    function createSavingsPoolERC20(
        address _tokenToSave,
        uint256 _amountToSave,
        uint256 _duration,
        uint256 _initialDeposit
    ) public {
        if (
            _duration != THREE_MONTHS &&
            _duration != SIX_MONTHS &&
            _duration != TWELVE_MONTHS
        ) revert TLR_InvalidTotalDuration();
        if (
            _initialDeposit > _amountToSave ||
            _amountToSave % _initialDeposit != 0
        ) revert TLR__InvalidInitialDeposit();
        if (
            _amountToSave == 0 ||
            _duration == 0 ||
            _initialDeposit == 0 ||
            _tokenToSave == address(0)
        ) revert TLR__INVALID_INPUTS();
        if (_amountToSave % INTERVAL != 0) revert TLR__InvalidDepositAmount();
        if (_duration % INTERVAL != 0) revert TLR_InvalidDuration();

        bytes32 savingsPoolId = keccak256(
            abi.encodePacked(msg.sender, block.timestamp, _tokenToSave)
        );
        emit SavingsPoolCreated(
            msg.sender,
            block.timestamp + _duration,
            _duration,
            block.timestamp,
            _initialDeposit,
            _tokenToSave,
            _amountToSave,
            _initialDeposit,
            0,
            block.timestamp + INTERVAL,
            _amountToSave / INTERVAL,
            block.timestamp
        );
        savingsPools[savingsPoolId] = SavingsPool({
            user: msg.sender,
            endDate: block.timestamp + _duration,
            duration: _duration,
            startDate: block.timestamp,
            totalSaved: 0,
            tokenToSave: _tokenToSave,
            amountToSave: _amountToSave,
            initialDeposit: _initialDeposit,
            totalWithdrawn: 0,
            nextDepositDate: block.timestamp + INTERVAL,
            numberOfDeposits: _amountToSave / INTERVAL,
            lastDepositedTimestamp: block.timestamp
        });

        IERC20(_tokenToSave).transferFrom(
            msg.sender,
            address(this),
            _initialDeposit
        );
    }

    function createSavingsPoolEth(
        uint256 _amountToSave,
        uint256 _duration,
        uint256 initialDeposit
    ) public payable {
        if (
            _duration != THREE_MONTHS &&
            _duration != SIX_MONTHS &&
            _duration != TWELVE_MONTHS
        ) revert TLR_InvalidTotalDuration();
        if (
            initialDeposit > _amountToSave ||
            _amountToSave % initialDeposit != 0
        ) revert TLR__InvalidInitialDeposit();
        if (_amountToSave == 0 || _duration == 0 || initialDeposit == 0)
            revert TLR__INVALID_INPUTS();
        if (_amountToSave % INTERVAL != 0) revert TLR__InvalidDepositAmount();
        if (_duration % INTERVAL != 0) revert TLR_InvalidDuration();
        if (msg.value != initialDeposit) revert TLR__InvalidInitialETHDeposit();

        uint256 remainingDepositAmount = _amountToSave - initialDeposit;

        bytes32 savingsPoolId = keccak256(
            abi.encodePacked(msg.sender, block.timestamp)
        );
        emit SavingsPoolCreated(
            msg.sender,
            block.timestamp + _duration,
            _duration,
            block.timestamp,
            initialDeposit,
            address(0),
            _amountToSave,
            initialDeposit,
            0,
            block.timestamp + INTERVAL,
            remainingDepositAmount / INTERVAL,
            block.timestamp
        );
        savingsPools[savingsPoolId] = SavingsPool({
            user: msg.sender,
            endDate: block.timestamp + _duration,
            duration: _duration,
            startDate: block.timestamp,
            totalSaved: msg.value,
            tokenToSave: address(0),
            amountToSave: _amountToSave,
            initialDeposit: initialDeposit,
            totalWithdrawn: 0,
            nextDepositDate: block.timestamp + INTERVAL,
            numberOfDeposits: remainingDepositAmount / INTERVAL,
            lastDepositedTimestamp: block.timestamp
        });
    }

    function depositToEthSavingPool(bytes32 _savingsPoolId) public payable {
        SavingsPool storage savingsPool = savingsPools[_savingsPoolId];
        uint256 remainingDepositAmount = savingsPool.amountToSave -
            savingsPool.totalSaved;
        if (block.timestamp > savingsPool.endDate)
            revert TLR__SavingPoolEnded();
        if (block.timestamp < savingsPool.nextDepositDate)
            revert TLR__SavingPoolDepositIntervalNotYet();
        if (msg.value % savingsPool.amountToSave != 0)
            revert TLR__InvalidEthDepositRatio();
        if (msg.value > remainingDepositAmount) revert TLR__ExcessEthDeposit();

        savingsPool.totalSaved += msg.value;
        savingsPool.numberOfDeposits -= 1;
        savingsPool.lastDepositedTimestamp = block.timestamp;
        if (savingsPool.numberOfDeposits > 0) {
            savingsPool.nextDepositDate += INTERVAL;
        }
        emit SavingsPoolDeposited(
            msg.sender,
            msg.value,
            savingsPool.totalSaved,
            savingsPool.nextDepositDate,
            savingsPool.numberOfDeposits,
            savingsPool.lastDepositedTimestamp
        );
    }

    function withdrawFromEthSavingPool(bytes32 _savingsPoolId) public {
        SavingsPool storage savingsPool = savingsPools[_savingsPoolId];
        if (block.timestamp < savingsPool.endDate)
            revert TLR__SavingPoolEnded();
        if (msg.sender != savingsPool.user) revert TLR__INVALID_INPUTS();
        if (savingsPool.totalSaved == 0) revert TLR__INVALID_INPUTS();

        payable(msg.sender).transfer(savingsPool.totalSaved);
        savingsPool.totalWithdrawn = savingsPool.totalSaved;
    }

    function withdrawFromERC20SavingPool(
        bytes32 _savingsPoolId,
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) public {
        SavingsPool storage savingsPool = savingsPools[_savingsPoolId];
        if (block.timestamp < savingsPool.endDate) {
            if (verifier.verify(_proof, _publicInputs))
                revert TLR__InValidProof();
        }

        if (msg.sender != savingsPool.user) revert TLR__INVALID_INPUTS();
        if (savingsPool.totalSaved == 0) revert TLR__INVALID_INPUTS();

        IERC20(savingsPool.tokenToSave).transfer(
            msg.sender,
            savingsPool.totalSaved
        );
        savingsPool.totalWithdrawn = savingsPool.totalSaved;
    }
}

interface IERC20 {
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    function transfer(
        address recipient,
        uint256 amount
    ) external returns (bool);

    function balanceOf(address account) external view returns (uint256);
}

interface IVerifier {
    function verify(
        bytes calldata _proof,
        bytes32[] calldata _publicInputs
    ) external view returns (bool);
}

/**
 * UserFlow:
 * User opens the app
 * Deposits funds to the inhouse wallet
 * User creates a savings pool
 * Savings Pool:
 * - User sets the amount to save
 * - User sets the duration
 * - User sets the interval terms
 * Options:
 * -Either deposit first month's savings or deposit the amounts equivalent to multiples of the interval amount
 * Objectives:
 * A function for user to create a savngs pool
 * A function for user to deposit funds to the savings pool based on the interval
 * A function for user to withdraw funds from the savings pool
 */
