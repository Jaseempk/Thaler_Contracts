import {
  assert,
  describe,
  test,
  clearStore,
  beforeAll,
  afterAll
} from "matchstick-as/assembly/index"
import { Address, BigInt, Bytes } from "@graphprotocol/graph-ts"
import { SavingsPoolCreated } from "../generated/schema"
import { SavingsPoolCreated as SavingsPoolCreatedEvent } from "../generated/ThalerSavingsPool/ThalerSavingsPool"
import { handleSavingsPoolCreated } from "../src/thaler-savings-pool"
import { createSavingsPoolCreatedEvent } from "./thaler-savings-pool-utils"

// Tests structure (matchstick-as >=0.5.0)
// https://thegraph.com/docs/en/developer/matchstick/#tests-structure-0-5-0

describe("Describe entity assertions", () => {
  beforeAll(() => {
    let user = Address.fromString("0x0000000000000000000000000000000000000001")
    let duration = BigInt.fromI32(234)
    let numberOfDeposits = BigInt.fromI32(234)
    let totalSaved = BigInt.fromI32(234)
    let tokenToSave = Address.fromString(
      "0x0000000000000000000000000000000000000001"
    )
    let amountToSave = BigInt.fromI32(234)
    let totalIntervals = 123
    let initialDeposit = BigInt.fromI32(234)
    let endDate = BigInt.fromI32(234)
    let startDate = BigInt.fromI32(234)
    let nextDepositDate = BigInt.fromI32(234)
    let lastDepositedTimestamp = BigInt.fromI32(234)
    let newSavingsPoolCreatedEvent = createSavingsPoolCreatedEvent(
      user,
      duration,
      numberOfDeposits,
      totalSaved,
      tokenToSave,
      amountToSave,
      totalIntervals,
      initialDeposit,
      endDate,
      startDate,
      nextDepositDate,
      lastDepositedTimestamp
    )
    handleSavingsPoolCreated(newSavingsPoolCreatedEvent)
  })

  afterAll(() => {
    clearStore()
  })

  // For more test scenarios, see:
  // https://thegraph.com/docs/en/developer/matchstick/#write-a-unit-test

  test("SavingsPoolCreated created and stored", () => {
    assert.entityCount("SavingsPoolCreated", 1)

    // 0xa16081f360e3847006db660bae1c6d1b2e17ec2a is the default address used in newMockEvent() function
    assert.fieldEquals(
      "SavingsPoolCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "user",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "SavingsPoolCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "duration",
      "234"
    )
    assert.fieldEquals(
      "SavingsPoolCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "numberOfDeposits",
      "234"
    )
    assert.fieldEquals(
      "SavingsPoolCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "totalSaved",
      "234"
    )
    assert.fieldEquals(
      "SavingsPoolCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "tokenToSave",
      "0x0000000000000000000000000000000000000001"
    )
    assert.fieldEquals(
      "SavingsPoolCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "amountToSave",
      "234"
    )
    assert.fieldEquals(
      "SavingsPoolCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "totalIntervals",
      "123"
    )
    assert.fieldEquals(
      "SavingsPoolCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "initialDeposit",
      "234"
    )
    assert.fieldEquals(
      "SavingsPoolCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "endDate",
      "234"
    )
    assert.fieldEquals(
      "SavingsPoolCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "startDate",
      "234"
    )
    assert.fieldEquals(
      "SavingsPoolCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "nextDepositDate",
      "234"
    )
    assert.fieldEquals(
      "SavingsPoolCreated",
      "0xa16081f360e3847006db660bae1c6d1b2e17ec2a-1",
      "lastDepositedTimestamp",
      "234"
    )

    // More assert options:
    // https://thegraph.com/docs/en/developer/matchstick/#asserts
  })
})
