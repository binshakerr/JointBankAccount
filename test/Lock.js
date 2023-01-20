const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");

describe("BankAccount", function () {
  async function deployBankAccount() {
    const [addr0, addr1, addr2, addr3] = await ethers.getSigners();
    const BankAccount = await ethers.getContractFactory("BankAccount");
    const bankAccount = await BankAccount.deploy();
    return { bankAccount, addr0, addr1, addr2, addr3 };
  }

  describe("Deployment", () => {
    it("should deploy without errors", async () => {
      await loadFixture(deployBankAccount);
    });
  });
});
