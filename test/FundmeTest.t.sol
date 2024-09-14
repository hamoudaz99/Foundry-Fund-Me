// SPDX-License-Identifier: MIT

pragma solidity 0.8.19;

import {Test,console} from "forge-std/Test.sol";
import {FundMe} from "../src/Fundme.sol";
import {DeployFundMe} from "../script/DeployFundme.s.sol";

contract FundMeTest is Test 
{ FundMe fundme;
uint256 sendValue = 0.1 ether;
uint256 StartingBalance= 10 ether; // The amount we send to each address we want to perform test with
  address User= makeAddr("ahmed"); // Create an address for the given string
  uint256 constant GAS_PRICE=1;
    function setUp() external
    {
     //  fundme = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306); // Deploying the contract
     DeployFundMe deployFundMe= new DeployFundMe();  // Creating an instance of the contract
     fundme= deployFundMe.run(); // Using the run function to actually deploy the contract (check the script file)
     vm.deal(User,StartingBalance); // Use a foundry cheatCode to send ether to the specified address
           

    }



    function testMinimumDollarisFive() public 
    { // console.log(number);

       assertEq(fundme.MINIMUM_USD(),5e18);

    }

    function testOwnerisMsgSender() public
    {

        assertEq(fundme.i_owner(),msg.sender);
    }
    
    function testPriceFeedVersionIsAccurate() public
    {
        uint256 version = fundme.getVersion();  
        assertEq(version,4);
    }
    function testFundFailsWithoutEnoughETH() public

    {  
        uint256 amountTosend=1; // 1e18 is equivalent to 1 eth which is greater than the minimum amount
         vm.expectRevert(); // Expect the next line to revert
        fundme.fund{value: amountTosend}(); // If this line revert the test will pass 
}
function testFundUpdatesFundedDataStructure() public
{
    vm.prank(User); // Will use the address User to call the function
    fundme.fund{value: sendValue}();
    uint256 amountFunded=fundme.getAddressToAmountFunded(User);
    console.log(fundme.getAddressToAmountFunded(User));
    assertEq(sendValue,amountFunded);

}  

function testAddsFunderToArrayOfFunders() public funded
{

    address funder= fundme.getFunder(0);
    assertEq(funder,User);
}

modifier funded()
{
 vm.prank(User);
 fundme.fund{value: sendValue}();
 _;
 }

function testOnlyOwnerCanWithdraw() public funded  //Using the funded modifier will allow us to avoid line repetition in our code to optimize him further
{
    vm.expectRevert(); // User is not the contract owner so we will expect the withdraw function to fail
    fundme.withdraw();
}
function testWithdrawAsSingleFunder() public funded
{
    uint256 startingOwnerBalance= fundme.getOwner().balance;
    uint256 startingFundMeBalance= address(fundme).balance;
    vm.prank(fundme.getOwner()); //Because only the owner can call the withdraw function
    fundme.withdraw();
    uint256 endingOwnerBalance= fundme.getOwner().balance;
    uint256 endingFundMeBalance= address(fundme).balance;
    assertEq(endingFundMeBalance,0);
    assertEq(startingOwnerBalance+startingFundMeBalance,endingOwnerBalance);

}

function testWithdrawFromMultipleFunders() public funded
{
    uint160 numberOfFunders=10; // uint160 need to be used while creating an address (address(i)) as it have the same number of bytes as an hex address
    uint160 startingFunderIndex=1; // WE start from 1 as the 0 is the burn address(0X0000...)
    for(uint160 i= startingFunderIndex;i<numberOfFunders;i++)
    {
        //vm.prank new address
        //vm.deal new address
        hoax(address(i),sendValue); // hoax is a forge method who combine both the prank and deal method 
        fundme.fund{value:sendValue}(); // Every generated address will fund the contract

    }
    uint256 startingOwnerBalance=fundme.getOwner().balance;
    uint256 startingFundMeBalance=address(fundme).balance;
    //Act
    uint256 gasStart=gasleft(); // A built in solidity function who tell how much gas is left in our transaction call , in this case as we didnt call any function , the returned value will be the default max gas the user will set 
    vm.startPrank(fundme.getOwner());
    fundme.withdraw(); // spend gas
    uint256 gasEnd = gasleft();
    uint256 gasUsed= (gasStart-gasEnd)*tx.gasprice;    // Now after making a function call , we can compare the first value (gasstart) and the second(gasEnd)
    vm.stopPrank();
    //Assert
    assert(address(fundme).balance==0);
    assert(startingFundMeBalance+startingOwnerBalance==fundme.getOwner().balance);

}

function testCheaperWithdrawFromMultipleFunders() public funded
{
    uint160 numberOfFunders=10; // uint160 need to be used while creating an address (address(i)) as it have the same number of bytes as an hex address
    uint160 startingFunderIndex=1; // WE start from 1 as the 0 is the burn address(0X0000...)
    for(uint160 i= startingFunderIndex;i<numberOfFunders;i++)
    {
        //vm.prank new address
        //vm.deal new address
        hoax(address(i),sendValue); // hoax is a forge method who combine both the prank and deal method 
        fundme.fund{value:sendValue}(); // Every generated address will fund the contract

    }
    uint256 startingOwnerBalance=fundme.getOwner().balance;
    uint256 startingFundMeBalance=address(fundme).balance;
    //Act
    uint256 gasStart=gasleft(); // A built in solidity function who tell how much gas is left in our transaction call , in this case as we didnt call any function , the returned value will be the default max gas the user will set 
    vm.startPrank(fundme.getOwner());
    fundme.cheaperWithdraw(); // spend gas
    uint256 gasEnd = gasleft();
    uint256 gasUsed= (gasStart-gasEnd)*tx.gasprice;    // Now after making a function call , we can compare the first value (gasstart) and the second(gasEnd)
    vm.stopPrank();
    //Assert
    assert(address(fundme).balance==0);
    assert(startingFundMeBalance+startingOwnerBalance==fundme.getOwner().balance);

}


}