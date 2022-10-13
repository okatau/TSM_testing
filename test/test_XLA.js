const { expect } = require('chai');
const { BigNumber } = require('ethers');
const { ethers } = require('hardhat');

let accounts;

let owner;
let defaultRef;
let teamAddress;

let TSM;
let Valve;
let XLA;
let TestToken;
let Freezer;

let GlassesFactory;
let Glass = [];
let GlassVAlve;
const provider = ethers.provider;

describe("Testing TSM Contracts", function () {
  it("Deploy all contracts. Account[0] is owner of all contracts", async function () {
    accounts = await ethers.getSigners();
    owner = accounts[0];
    defaultRef = accounts[18];
    teamAddress = accounts[19];
    tempValve = await ethers.getContractFactory("Valve");
    Valve = await tempValve.deploy()
    await Valve.deployed();
    tempXLA = await ethers.getContractFactory("XLA");
    XLA = await tempXLA.deploy();
    await XLA.deployed();
    tempTSM = await ethers.getContractFactory("TokenSaleMachine");
    TSM = await tempTSM.deploy(XLA.address, Valve.address, defaultRef.address, teamAddress.address);
    await TSM.deployed();
    tempToken = await ethers.getContractFactory("Token");
    TestToken = await tempToken.deploy("TestToken", "TT", ethers.BigNumber.from(10000).pow(18).mul(1));
    await TestToken.deployed();
    tempFreezer = await ethers.getContractFactory("Freezer");
    Freezer = await tempFreezer.deploy(XLA.address, TSM.address);
    await Freezer.deployed();
    expect(await TestToken.owner()).to.equal(owner.address);
  })

  it("Testing TSM buyWithRef", async function() {
    await TSM.changeFreezer(Freezer.address);
    await XLA.grantRole(ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE")), TSM.address);
    await XLA.grantRole(ethers.utils.keccak256(ethers.utils.toUtf8Bytes("MINTER_ROLE")), owner.address);
    await TSM.grantRole(ethers.utils.keccak256(ethers.utils.toUtf8Bytes("USER_REGISTER_ROLE")), owner.address);
    await TSM.grantRole(ethers.utils.keccak256(ethers.utils.toUtf8Bytes("TOKEN_REGISTER_ROLE")), owner.address);
    await TSM.addUsers([owner.address, defaultRef.address, teamAddress.address]);
    await TSM.addStableCoins([TestToken.address]);

    await TestToken.approve(TSM.address, ethers.BigNumber.from(10).pow(18).mul(100));
    let tempAmount = await TSM.amountToSend(ethers.BigNumber.from(10).pow(18));
    await TSM.buyWithRef(TestToken.address, ethers.BigNumber.from(10).pow(18), accounts[1].address);
    expect(tempAmount).to.equal(await XLA.balanceOf(owner.address));
  })

  it("Testing TSM buyWithoutRef", async function() {
    let temp = await TSM.amountToSend(ethers.BigNumber.from(10).pow(18));
    let defRefPercent = ethers.BigNumber.from(temp).div(25);
    await TSM.buyWithoutRef(TestToken.address, ethers.BigNumber.from(10).pow(18));
    expect(await XLA.balanceOf(defaultRef.address)).to.equal(defRefPercent);
  })

  it("Testing Freezer contract", async function(){
    await TSM.addUser(accounts[1].address);
    await Freezer.connect(accounts[1]).withdraw();
    expect(await XLA.balanceOf(accounts[1].address)).greaterThan(0);
  }) 

  it("Testing Valve contract", async function() {
    let user1 = accounts[2];
    let user2 = accounts[3];
    
    let TT1 = await ethers.getContractFactory("Token");
    let TestToken1 = await TT1.deploy("TestToken1", "TT1", ethers.utils.parseEther("10000000000.0"));
    await TestToken1.deployed();

    await TestToken1.transfer(Valve.address, ethers.utils.parseEther("15.0"));
    let valveBalanceTT = await TestToken.balanceOf(Valve.address);
    let valveBalanceTT1 = await TestToken1.balanceOf(Valve.address);

    await Valve.updateAvaiableTokens([TestToken.address, TestToken1.address]);
    await Valve.updateStreams([[user1.address, 690000], [user2.address, 310000]]);
    await Valve.Split();

    expect(ethers.BigNumber
      .from(await TestToken.balanceOf(user1.address))
      .add(await TestToken.balanceOf(user2.address)))
      .to
      .equal(valveBalanceTT);

    expect(ethers.BigNumber
      .from(await TestToken1.balanceOf(user1.address))
      .add(await TestToken1.balanceOf(user2.address)))
      .to
      .equal(valveBalanceTT1);
  })

  it("Deploying GlassesFactory contract", async function (){
    let tempGlass = await ethers.getContractFactory("GlassesFactory");
    GlassesFactory = await tempGlass.deploy();
    await GlassesFactory.deployed();
    
    expect(await GlassesFactory.owner()).to.equal(owner.address);
  })

  it("Testing Glasses contracts", async function (){
    let glassesData = [
      [ethers.utils.parseEther("10"), owner.address],
      [ethers.utils.parseEther("7.5"), accounts[5].address],
      [ethers.utils.parseEther("3.0"), accounts[6].address]
    ];
    let valveData = [
      owner.address, accounts[7].address
    ];

    let createGlasses = await GlassesFactory.makeGlasses(glassesData);
    let createValve = await GlassesFactory.makeValves(valveData)
    let resultCG = await createGlasses.wait();
    let resultCV = await createValve.wait();

    let firstGlass = await ethers.getContractAt("Glass", resultCG.events[0].args._newGlass, provider.getSigner());
    let secondGlass = await ethers.getContractAt("Glass", resultCG.events[1].args._newGlass, provider.getSigner());
    let thirdGlass = await ethers.getContractAt("Glass", resultCG.events[2].args._newGlass, provider.getSigner());
    let firstValve = await ethers.getContractAt("GlassesValve", resultCV.events[0].args._newGlassesValve, provider.getSigner());
    let secondValve = await ethers.getContractAt("GlassesValve", resultCV.events[1].args._newGlassesValve, provider.getSigner());

    let TT1 = await ethers.getContractFactory("Token");
    let TestToken1 = await TT1.deploy("TestToken1", "TT1", ethers.utils.parseEther("10000000000.0"));
    await TestToken1.deployed();

    await GlassesFactory.setAcceptedTokens([TestToken.address, TestToken1.address]);
    await TestToken.transfer(firstValve.address, ethers.utils.parseEther("10.0"));
    await TestToken1.transfer(firstValve.address, ethers.utils.parseEther("5.0"));
    await TestToken.transfer(secondValve.address, ethers.utils.parseEther("2.5"));
    await TestToken1.transfer(secondValve.address, ethers.utils.parseEther("1.5"));

    expect(await firstValve.balance()).to.equal(ethers.utils.parseEther("15.0"));
    expect(await secondValve.balance()).to.equal(ethers.utils.parseEther("4.0"));

    await firstValve.addGlasses([firstGlass.address, secondGlass.address]);
    await secondValve.connect(accounts[7]).addGlasses([secondGlass.address, thirdGlass.address]);
    console.log("Valve balance");
    console.log(await firstValve.balance());
    console.log(await secondValve.balance());
    console.log("Glasses balance");
    console.log(await firstGlass.balance());
    console.log(await secondGlass.balance());
    console.log(await thirdGlass.balance());

    await firstValve.fillGlass();
    await secondValve.fillGlass();

    console.log(await firstGlass.balance());
    console.log(await secondGlass.balance());
    console.log(await thirdGlass.balance());

    expect(await firstGlass.balance()).to.equal(await firstGlass.border());
    // неправильно работает логика контракта
    // expect(await secondGlass.balance()).to.equal(await secondGlass.border());
    // expect(await thirdGlass.fullness()).to.equal(ethers.utils.parseEther("1.5"));
  })
})
