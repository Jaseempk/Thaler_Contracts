import { newMockEvent } from "matchstick-as"
import { ethereum, Address, BigInt, Bytes } from "@graphprotocol/graph-ts"
import {
  CharityWhitelisted,
  EarlyWithdrawalDonation,
  SavingsPoolCreated,
  SavingsPoolERC20Deposited,
  SavingsPoolETHDeposited,
  WithdrawFromERC20Pool,
  WithdrawFromEthPool
} from "../generated/ThalerSavingsPool/ThalerSavingsPool"

export function createCharityWhitelistedEvent(
  charityAddress: Address
): CharityWhitelisted {
  let charityWhitelistedEvent = changetype<CharityWhitelisted>(newMockEvent())

  charityWhitelistedEvent.parameters = new Array()

  charityWhitelistedEvent.parameters.push(
    new ethereum.EventParam(
      "charityAddress",
      ethereum.Value.fromAddress(charityAddress)
    )
  )

  return charityWhitelistedEvent
}

export function createEarlyWithdrawalDonationEvent(
  user: Address,
  charityAddress: Address,
  amountDonated: BigInt,
  tokenToSave: Address
): EarlyWithdrawalDonation {
  let earlyWithdrawalDonationEvent =
    changetype<EarlyWithdrawalDonation>(newMockEvent())

  earlyWithdrawalDonationEvent.parameters = new Array()

  earlyWithdrawalDonationEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )
  earlyWithdrawalDonationEvent.parameters.push(
    new ethereum.EventParam(
      "charityAddress",
      ethereum.Value.fromAddress(charityAddress)
    )
  )
  earlyWithdrawalDonationEvent.parameters.push(
    new ethereum.EventParam(
      "amountDonated",
      ethereum.Value.fromUnsignedBigInt(amountDonated)
    )
  )
  earlyWithdrawalDonationEvent.parameters.push(
    new ethereum.EventParam(
      "tokenToSave",
      ethereum.Value.fromAddress(tokenToSave)
    )
  )

  return earlyWithdrawalDonationEvent
}

export function createSavingsPoolCreatedEvent(
  user: Address,
  duration: BigInt,
  numberOfDeposits: BigInt,
  totalSaved: BigInt,
  tokenToSave: Address,
  amountToSave: BigInt,
  totalIntervals: i32,
  initialDeposit: BigInt,
  endDate: BigInt,
  startDate: BigInt,
  nextDepositDate: BigInt,
  lastDepositedTimestamp: BigInt
): SavingsPoolCreated {
  let savingsPoolCreatedEvent = changetype<SavingsPoolCreated>(newMockEvent())

  savingsPoolCreatedEvent.parameters = new Array()

  savingsPoolCreatedEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )
  savingsPoolCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "duration",
      ethereum.Value.fromUnsignedBigInt(duration)
    )
  )
  savingsPoolCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "numberOfDeposits",
      ethereum.Value.fromUnsignedBigInt(numberOfDeposits)
    )
  )
  savingsPoolCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "totalSaved",
      ethereum.Value.fromUnsignedBigInt(totalSaved)
    )
  )
  savingsPoolCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "tokenToSave",
      ethereum.Value.fromAddress(tokenToSave)
    )
  )
  savingsPoolCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "amountToSave",
      ethereum.Value.fromUnsignedBigInt(amountToSave)
    )
  )
  savingsPoolCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "totalIntervals",
      ethereum.Value.fromUnsignedBigInt(BigInt.fromI32(totalIntervals))
    )
  )
  savingsPoolCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "initialDeposit",
      ethereum.Value.fromUnsignedBigInt(initialDeposit)
    )
  )
  savingsPoolCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "endDate",
      ethereum.Value.fromUnsignedBigInt(endDate)
    )
  )
  savingsPoolCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "startDate",
      ethereum.Value.fromUnsignedBigInt(startDate)
    )
  )
  savingsPoolCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "nextDepositDate",
      ethereum.Value.fromUnsignedBigInt(nextDepositDate)
    )
  )
  savingsPoolCreatedEvent.parameters.push(
    new ethereum.EventParam(
      "lastDepositedTimestamp",
      ethereum.Value.fromUnsignedBigInt(lastDepositedTimestamp)
    )
  )

  return savingsPoolCreatedEvent
}

export function createSavingsPoolERC20DepositedEvent(
  user: Address,
  savingsPoolId: Bytes,
  depositedAmount: BigInt,
  totalSaved: BigInt,
  nextDepositDate: BigInt,
  numberOfDeposits: BigInt,
  lastDepositedTimestamp: BigInt
): SavingsPoolERC20Deposited {
  let savingsPoolErc20DepositedEvent =
    changetype<SavingsPoolERC20Deposited>(newMockEvent())

  savingsPoolErc20DepositedEvent.parameters = new Array()

  savingsPoolErc20DepositedEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )
  savingsPoolErc20DepositedEvent.parameters.push(
    new ethereum.EventParam(
      "savingsPoolId",
      ethereum.Value.fromFixedBytes(savingsPoolId)
    )
  )
  savingsPoolErc20DepositedEvent.parameters.push(
    new ethereum.EventParam(
      "depositedAmount",
      ethereum.Value.fromUnsignedBigInt(depositedAmount)
    )
  )
  savingsPoolErc20DepositedEvent.parameters.push(
    new ethereum.EventParam(
      "totalSaved",
      ethereum.Value.fromUnsignedBigInt(totalSaved)
    )
  )
  savingsPoolErc20DepositedEvent.parameters.push(
    new ethereum.EventParam(
      "nextDepositDate",
      ethereum.Value.fromUnsignedBigInt(nextDepositDate)
    )
  )
  savingsPoolErc20DepositedEvent.parameters.push(
    new ethereum.EventParam(
      "numberOfDeposits",
      ethereum.Value.fromUnsignedBigInt(numberOfDeposits)
    )
  )
  savingsPoolErc20DepositedEvent.parameters.push(
    new ethereum.EventParam(
      "lastDepositedTimestamp",
      ethereum.Value.fromUnsignedBigInt(lastDepositedTimestamp)
    )
  )

  return savingsPoolErc20DepositedEvent
}

export function createSavingsPoolETHDepositedEvent(
  user: Address,
  savingsPoolId: Bytes,
  depositedAmount: BigInt,
  totalSaved: BigInt,
  nextDepositDate: BigInt,
  numberOfDeposits: BigInt,
  lastDepositedTimestamp: BigInt
): SavingsPoolETHDeposited {
  let savingsPoolEthDepositedEvent =
    changetype<SavingsPoolETHDeposited>(newMockEvent())

  savingsPoolEthDepositedEvent.parameters = new Array()

  savingsPoolEthDepositedEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )
  savingsPoolEthDepositedEvent.parameters.push(
    new ethereum.EventParam(
      "savingsPoolId",
      ethereum.Value.fromFixedBytes(savingsPoolId)
    )
  )
  savingsPoolEthDepositedEvent.parameters.push(
    new ethereum.EventParam(
      "depositedAmount",
      ethereum.Value.fromUnsignedBigInt(depositedAmount)
    )
  )
  savingsPoolEthDepositedEvent.parameters.push(
    new ethereum.EventParam(
      "totalSaved",
      ethereum.Value.fromUnsignedBigInt(totalSaved)
    )
  )
  savingsPoolEthDepositedEvent.parameters.push(
    new ethereum.EventParam(
      "nextDepositDate",
      ethereum.Value.fromUnsignedBigInt(nextDepositDate)
    )
  )
  savingsPoolEthDepositedEvent.parameters.push(
    new ethereum.EventParam(
      "numberOfDeposits",
      ethereum.Value.fromUnsignedBigInt(numberOfDeposits)
    )
  )
  savingsPoolEthDepositedEvent.parameters.push(
    new ethereum.EventParam(
      "lastDepositedTimestamp",
      ethereum.Value.fromUnsignedBigInt(lastDepositedTimestamp)
    )
  )

  return savingsPoolEthDepositedEvent
}

export function createWithdrawFromERC20PoolEvent(
  user: Address,
  endDate: BigInt,
  startDate: BigInt,
  timeStamp: BigInt,
  totalSaved: BigInt,
  tokenSaved: Address,
  poolDuration: BigInt,
  savingsPoolId: Bytes,
  totalWithdrawn: BigInt
): WithdrawFromERC20Pool {
  let withdrawFromErc20PoolEvent =
    changetype<WithdrawFromERC20Pool>(newMockEvent())

  withdrawFromErc20PoolEvent.parameters = new Array()

  withdrawFromErc20PoolEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )
  withdrawFromErc20PoolEvent.parameters.push(
    new ethereum.EventParam(
      "endDate",
      ethereum.Value.fromUnsignedBigInt(endDate)
    )
  )
  withdrawFromErc20PoolEvent.parameters.push(
    new ethereum.EventParam(
      "startDate",
      ethereum.Value.fromUnsignedBigInt(startDate)
    )
  )
  withdrawFromErc20PoolEvent.parameters.push(
    new ethereum.EventParam(
      "timeStamp",
      ethereum.Value.fromUnsignedBigInt(timeStamp)
    )
  )
  withdrawFromErc20PoolEvent.parameters.push(
    new ethereum.EventParam(
      "totalSaved",
      ethereum.Value.fromUnsignedBigInt(totalSaved)
    )
  )
  withdrawFromErc20PoolEvent.parameters.push(
    new ethereum.EventParam(
      "tokenSaved",
      ethereum.Value.fromAddress(tokenSaved)
    )
  )
  withdrawFromErc20PoolEvent.parameters.push(
    new ethereum.EventParam(
      "poolDuration",
      ethereum.Value.fromUnsignedBigInt(poolDuration)
    )
  )
  withdrawFromErc20PoolEvent.parameters.push(
    new ethereum.EventParam(
      "savingsPoolId",
      ethereum.Value.fromFixedBytes(savingsPoolId)
    )
  )
  withdrawFromErc20PoolEvent.parameters.push(
    new ethereum.EventParam(
      "totalWithdrawn",
      ethereum.Value.fromUnsignedBigInt(totalWithdrawn)
    )
  )

  return withdrawFromErc20PoolEvent
}

export function createWithdrawFromEthPoolEvent(
  user: Address,
  endDate: BigInt,
  startDate: BigInt,
  timeStamp: BigInt,
  totalSaved: BigInt,
  poolDuration: BigInt,
  savingsPoolId: Bytes,
  totalWithdrawn: BigInt
): WithdrawFromEthPool {
  let withdrawFromEthPoolEvent = changetype<WithdrawFromEthPool>(newMockEvent())

  withdrawFromEthPoolEvent.parameters = new Array()

  withdrawFromEthPoolEvent.parameters.push(
    new ethereum.EventParam("user", ethereum.Value.fromAddress(user))
  )
  withdrawFromEthPoolEvent.parameters.push(
    new ethereum.EventParam(
      "endDate",
      ethereum.Value.fromUnsignedBigInt(endDate)
    )
  )
  withdrawFromEthPoolEvent.parameters.push(
    new ethereum.EventParam(
      "startDate",
      ethereum.Value.fromUnsignedBigInt(startDate)
    )
  )
  withdrawFromEthPoolEvent.parameters.push(
    new ethereum.EventParam(
      "timeStamp",
      ethereum.Value.fromUnsignedBigInt(timeStamp)
    )
  )
  withdrawFromEthPoolEvent.parameters.push(
    new ethereum.EventParam(
      "totalSaved",
      ethereum.Value.fromUnsignedBigInt(totalSaved)
    )
  )
  withdrawFromEthPoolEvent.parameters.push(
    new ethereum.EventParam(
      "poolDuration",
      ethereum.Value.fromUnsignedBigInt(poolDuration)
    )
  )
  withdrawFromEthPoolEvent.parameters.push(
    new ethereum.EventParam(
      "savingsPoolId",
      ethereum.Value.fromFixedBytes(savingsPoolId)
    )
  )
  withdrawFromEthPoolEvent.parameters.push(
    new ethereum.EventParam(
      "totalWithdrawn",
      ethereum.Value.fromUnsignedBigInt(totalWithdrawn)
    )
  )

  return withdrawFromEthPoolEvent
}
