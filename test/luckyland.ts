const { expect } = require("chai");
const { ethers } = require("hardhat");
import { BigNumber } from "ethers";
import { Address } from "cluster";
import { LuckyLandFactory } from "../typechain/LuckyLandFactory";
import { ILuckyLandCard } from "../typechain/ILuckyLandCard";

describe("Deploy", async () => {
  let luckyLandFactory: LuckyLandFactory
  let luckyLandCard: ILuckyLandCard
  let ownerAddress: string
  let user: Address
  let controller: Address

  beforeEach(async () => {

    const signers = await ethers.getSigners();
    for (const account of signers) {
      // console.log(account.address);
    }

    ownerAddress = signers[0].address;
    user = signers[1];
    controller = signers[2];

  });

  describe("ERC721", async () => {
    it("owner balance", async () => {

    });
  });

  describe("Claim", async () => {
    it("user Claim", async () => {


    });
  });

  describe("WithDraw", async () => {
    it("contraller withdraw", async () => {

    });
  });
});