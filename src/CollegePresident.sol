// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract CollegePresident is Ownable {
    string private collegePresident;

    event CollegePresidentChanged(string president);

    function makeCollegePresident(string memory president) public onlyOwner{
        collegePresident = president;
        emit CollegePresidentChanged(president);
    }

    function getCollegePresident() public view returns (string memory) {
        return collegePresident;
    }
}
