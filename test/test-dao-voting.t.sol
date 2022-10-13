// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {IGovernor} from "../lib/openzeppelin-contracts/contracts/governance/IGovernor.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {GovernorContract} from "../src/GovernorContract.sol";
import {CollegePresident} from "../src/CollegePresident.sol";

contract TestDAOVoting is Test {
    uint256 public constant MIN_DELAY = 3600; // 1 hour
    address[] public proposors;
    address[] public executors;

    uint256 public constant VOTING_DELAY = 1; // 1 block till the proposal becomes active
    uint256 public constant VOTING_PERIOD = 5; // 5 blocks is the voting duration
    uint256 public constant QUORUM_PERCENTAGE = 4;

    GovernanceToken governanceToken;
    TimeLock timeLock;
    GovernorContract governorContract;
    CollegePresident collegePresident;

    uint proposalID;

    function setUp() public {
        /////////////////////////////////////////////
        // Setting Up The Contracts
        /////////////////////////////////////////////

        // Deploying the governanceToken
        governanceToken = new GovernanceToken();

        // Delegating the voting rights to ourselves
        governanceToken.delegate(address(this));
        assertTrue(governanceToken.numCheckpoints(address(this)) != 0);

        // Deploying Timelock with a min_delay of 3600 and an empty list of proposors and executors.
        timeLock = new TimeLock(
            MIN_DELAY, 
            proposors, 
            executors
        );

        // Deploying GovernorContract with very low values of voting delays and voting periods for the sake of testing
        governorContract = new GovernorContract(
            governanceToken,
            timeLock,
            VOTING_DELAY,
            VOTING_PERIOD,
            QUORUM_PERCENTAGE
        );

        // Making the proposor -> GovernorContract
        timeLock.grantRole(keccak256("PROPOSER_ROLE"), address(governorContract));

        // Making the executor -> address(0) -> everyone
        timeLock.grantRole(keccak256("EXECUTOR_ROLE"), address(0));

        // Revoking admin access of Timelock admin
        timeLock.revokeRole(keccak256("TIMELOCK_ADMIN_ROLE"), msg.sender);

        //Let's deploy the collegePresident contract (the contract that we want to be governed)
        collegePresident = new CollegePresident();

        // Let's now transfer the ownership of the collegePresident to the timeLock contract
        collegePresident.transferOwnership(address(timeLock));

        //////////////////////
        // DAO Proposal Step
        //////////////////////
        assertEq(proposalID, 0);

        // We need to create a few parameters here to call the `propose` function:
        // 1. targets array: The contract you want to call a function in
        // 2. values array: The amount of Ether you want to send to those targets
        // 3. calldatas: Encoded version of the function calls to the target contracts
        // 4. proposalDescription: A string describing your proposal for others to see and form an opinion before voting
        uint256[] memory values = new uint[](1);
        values[0] = 0;

        address[] memory targets = new address[](1);
        targets[0] = address(collegePresident);

        bytes memory makeCollegePresidentCall = abi.encodeWithSelector(collegePresident.makeCollegePresident.selector, "Yami Sukehiro");
        bytes[] memory calldatas = new bytes[](1); 
        calldatas[0] = makeCollegePresidentCall;

        string memory proposalDescription = "Yami Sukehiro always pushes beyond his current limit and inspires his team to do the same. Therefore, he should be the college president";
        
        // Since only the governorContract can propose. The governorContract will propose a new College President name
        proposalID = governorContract.propose(
                        targets,
                        values,
                        calldatas,
                        proposalDescription
                     );

        // If the governorContract.propose function executed as intended, we should have got a new value of proposalID
        assertTrue(proposalID != 0);
        
        // Since the proposal has just been created and not passed the VOTING_DELAY, the proposal should be in Pending state.
        assertTrue(governorContract.state(proposalID) == IGovernor.ProposalState.Pending);

        // Moving ahead 1 block which is the VOTING_DELAY that we had set
        vm.warp(block.timestamp + VOTING_DELAY);
        vm.roll(block.timestamp + VOTING_DELAY);

        // Since the proposal had been created previously and now we have moved ahead by VOTING_DELAY block(s), the proposal should be in ACTIVE state
        assertTrue(governorContract.state(proposalID) == IGovernor.ProposalState.Active);
    }

    function test_voting() public {
        assertTrue(governorContract.state(proposalID) == IGovernor.ProposalState.Active);

        // Let's now vote
        // Remember we (address(this), which is this particular contract in this case) can vote since we have all the GovernanceTokens and we have delegated the voting power to ourselves
        uint256 governanceTokenBalance = governanceToken.balanceOf(address(this));
        uint256 eligibleVotes = governanceToken.getVotes(address(this));

        emit log_named_uint("msg.sender voting power", eligibleVotes);
        emit log_named_uint("msg.sender token balance", governanceTokenBalance);

        assertEq(governanceTokenBalance, eligibleVotes);

        // Let's assume that we will use the following standards for voting:
        // 0 : Against 
        // 1 : For  
        // 2 : Abstain

        uint8 support = 1; // We are voting For
        string memory reason = "I like the Black Bulls";

        governorContract.castVoteWithReason(
            proposalID, 
            support, 
            reason
        );

        // Let's check the proposal state now that it has been voted yes by us.
        // Since the VOTING_PERIOD is still going on, the state should still be ACTIVE
        assertTrue(governorContract.state(proposalID) == IGovernor.ProposalState.Active);

        // After the VOTING_PERIOD has passed, the proposal should succeed
        vm.warp(block.timestamp + VOTING_PERIOD + 1);
        vm.roll(block.timestamp + VOTING_PERIOD + 1);

        assertTrue(governorContract.state(proposalID) == IGovernor.ProposalState.Succeeded);
    }
}
