# DAO Tutorial

## What is a DAO?

A DAO, or “Decentralized Autonomous Organization,” is a community-led entity with no central authority. It is fully autonomous and transparent: smart contracts lay the foundational rules, execute the agreed upon decisions, and at any point, proposals, voting, and even the very code itself can be publicly audited.

Ultimately, a DAO is governed entirely by its individual members who collectively make critical decisions about the future of the project, such as technical upgrades and treasury allocations.

Generally speaking, community members create proposals about the future operations of the protocol and then come together to vote on each proposal. Proposals that achieve some predefined level of consensus are then accepted and enforced by the rules instantiated within the smart contract.

## Motivation

In our example, let's assume that we have a college and that college needs to decide who the college president should be.

So, the most effective method of implementing the decision of every stakeholder is to create a college DAO that can vote of this matter.

## Setting Up Forge:

0. Open the terminal of your choice.
1. Download `foundryup` by using the following command:
```shell
curl -L https://foundry.paradigm.xyz | bash
```
2. (Optional) If for some reason, step 1 is not working for you, try building this from source using the instructions provided on [Foundry's official wiki](https://book.getfoundry.sh/getting-started/installation#building-from-source)
3. This will download foundryup. Then install Foundry by running:
```shell
foundryup
```
4. Check whether `forge` has been installed or not by running the following command:
```shell
forge --version
```

## Setting up the project folder

0. Setup the folder that you want to use and initialize forge.
1. Navigate to the location of your choice.
2. Then use the following commands:
```shell
mkdir my-app
cd my-app
forge init
```
3. Now open this folder in VS Code (or any editor of your choice). You should get a file structure looking like this:

<img width="576" alt="Screenshot 2022-10-03 at 12 14 17 PM" src="https://user-images.githubusercontent.com/32522659/193516127-f10d748e-b993-43fc-a5d3-f6ec658d84e4.png">

4. You can run `forge build` and then `forge test` to see whether the defaults are working correctly or not.

<img width="1728" alt="Screenshot 2022-10-05 at 5 40 16 PM" src="https://user-images.githubusercontent.com/32522659/194057375-68d9d541-4b0c-47d9-bbfd-79061c3bf21d.png">

## Importing dependecies

We would be importing an ERC20 token contract from the OpenZeppelin repo, which is the most used and standard repository used across the Solidity development ecosystem.

To install this dependency, use the following command:

```shell
forge install @openzeppelin/openzeppelin-contracts --no-commit
```

You can see all the installed dependencies by navigating to `lib/openzeppelin-contracts`.

## Writing our DAO Contracts

### The CollegePresident Contract

0. First go ahead and delete `src/Counter.sol` and `test/Counter.t.sol`.
1. Create a file `src/CollegePresident.sol`. This will be a simple `ownable` contract that will be used to select a new president of the college and also to retrieve their name.
2. The code in this file will look something like this:

```solidity

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


```

### The ERC20Votes contract

We now want a mechanism by which people who are eligible to vote for any particular proposal (the name of the college president) in this case. So, we will use ERC20 tokens to track who is eligible to vote and exactly how many votes they can cast.

Earlier we deployed simple ERC20 tokens, now what we will do is deploy `ERC20Votes` which is an extension of ERC20 providing the logic for tracking the voting power of each token holder. 

This is also available from OpenZeppelin's ERC20 library.

So, the code for `src/GovernanceToken.sol` would look something like this:

```solidity

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";

/*
 * The ERC20Votes extension keeps a history (checkpoints) of each account's vote power. Vote power can be delegated either
 * by calling the {delegate} function directly, or by providing a signature to be used with {delegateBySig}. Voting
 * power can be queried through the public accessors {getVotes} and {getPastVotes}.
 *
 * By default, token balance does not account for voting power. This makes transfers cheaper. The downside is that it
 * requires users to delegate to themselves in order to activate checkpoints and have their voting power tracked.
 *
*/

contract GovernanceToken is ERC20Votes {
    uint256 public maxTokenSupply = 100_000*1e18;

    constructor() ERC20("CollegeDAOToken", "CDT") ERC20Permit("CollegeDAOToken") {
        _mint(msg.sender, maxTokenSupply);
    }

    // The functions below are overrides required by Solidity.

    function _afterTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override(ERC20Votes) {
        super._afterTokenTransfer(from, to, amount);
    }

    function _mint(address to, uint256 amount) internal override(ERC20Votes) {
        super._mint(to, amount);
    }

    function _burn(address account, uint256 amount) internal override(ERC20Votes) {
        super._burn(account, amount);
    }
}

```

Once again check if everything is compiling correctly or not using the `forge build` command. If everything went well, you should see something like this:

```shell

[⠢] Compiling...
[⠒] Compiling 15 files with 0.8.17
[⠢] Solc 0.8.17 finished in 773.33ms
Compiler run successful

```

### GovernorContract

To generate our governor contract, head over to the [OpenZeppelin Contracts Wizard](https://docs.openzeppelin.com/contracts/4.x/wizard) and choose the `Governor` option, change the name to `GovernorContract`. 

If you want, you can edit the rest of the settings, but in this tutorial we would be going ahead with the default settings.

So now, we will copy the contract code from the wizard and paste it into `src/GovernorContract.sol`. The contract should look something like this:

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "../lib/openzeppelin-contracts/contracts/governance/Governor.sol";
import "../lib/openzeppelin-contracts/contracts/governance/extensions/GovernorSettings.sol";
import "../lib/openzeppelin-contracts/contracts/governance/extensions/GovernorCountingSimple.sol";
import "../lib/openzeppelin-contracts/contracts/governance/extensions/GovernorVotes.sol";
import "../lib/openzeppelin-contracts/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "../lib/openzeppelin-contracts/contracts/governance/extensions/GovernorTimelockControl.sol";

contract GovernorContract is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction, GovernorTimelockControl {
    constructor(IVotes _token, TimelockController _timelock)
        Governor("GovernorContract")
        GovernorSettings(1 /* 1 block */, 50400 /* 1 week */, 0)
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
    {}

    // The following functions are overrides required by Solidity.

    function votingDelay()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingDelay();
    }

    function votingPeriod()
        public
        view
        override(IGovernor, GovernorSettings)
        returns (uint256)
    {
        return super.votingPeriod();
    }

    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFraction)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    function state(uint256 proposalId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (ProposalState)
    {
        return super.state(proposalId);
    }

    function propose(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, string memory description)
        public
        override(Governor, IGovernor)
        returns (uint256)
    {
        return super.propose(targets, values, calldatas, description);
    }

    function proposalThreshold()
        public
        view
        override(Governor, GovernorSettings)
        returns (uint256)
    {
        return super.proposalThreshold();
    }

    function _execute(uint256 proposalId, address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
    {
        super._execute(proposalId, targets, values, calldatas, descriptionHash);
    }

    function _cancel(address[] memory targets, uint256[] memory values, bytes[] memory calldatas, bytes32 descriptionHash)
        internal
        override(Governor, GovernorTimelockControl)
        returns (uint256)
    {
        return super._cancel(targets, values, calldatas, descriptionHash);
    }

    function _executor()
        internal
        view
        override(Governor, GovernorTimelockControl)
        returns (address)
    {
        return super._executor();
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(Governor, GovernorTimelockControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}

```

Make sure to change the way the rest of governor extensions are imported into your contract.

Now, if you remember we had hard set values for voting delays, voting periods and quorum percentages. What if we wanted to make customized and variable? Well, we would simply pass in more arguments to the `GovernorContract` constructor and then pass those variable values to the relevant `extension constructor(s)`. Here is what it would look like in our scenario:

```solidity

contract GovernorContract is Governor, GovernorSettings, GovernorCountingSimple, GovernorVotes, GovernorVotesQuorumFraction, GovernorTimelockControl {
    constructor(
        IVotes _token, 
        TimelockController _timelock,
        uint256 _votingDelay,
        uint256 _votingPeriod,
        uint256 _quorumPercentage
        )
        Governor("GovernorContract")
        GovernorSettings(
            _votingDelay, 
            _votingPeriod, 
            0
        )
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
        GovernorTimelockControl(_timelock)
    {}
    .
    .
    .
    .
}

```

### Timelock Contract

The Timelock contract is intended to handle the delay after a particular proposal has passed and before executing it.

Why is that the case?

Within this stipulated time, people that do not want to be part of the governance can get out before the execution of the contract.

And since, Timelock contract is the contract responsible for the execution of the main contract (`CollegePresident` in our case), it is also the owner of that contract.

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../lib/openzeppelin-contracts/contracts/governance/TimelockController.sol";

contract TimeLock is TimelockController {
  // minDelay is how long you have to wait before executing
  // proposers is the list of addresses that can propose
  // executors is the list of addresses that can execute
  constructor(
    uint256 minDelay,
    address[] memory proposers,
    address[] memory executors
  ) TimelockController(minDelay, proposers, executors, msg.sender) {
    
  }
}

```

So, this is the end of writing all our contracts for the DAO. Now, we would `forge build` once again to verify that every contract is compiling correctly and possibly functioning as intended. If everything goes right, you'll see something like this:

```shell

saxenism@Rahuls-MacBook-Pro gnosis-builders-dao-project % forge build
[⠢] Compiling...
[⠒] Compiling 21 files with 0.8.17
[⠢] Solc 0.8.17 finished in 1.79s
Compiler run successful

```

## Preparing to deploy our token contract

0. Any blockchain is a chain of blocks and the people responsible for creating and adding new blocks to this chain are called miners or stakers. As normal users of blockchain, we provide some fee to these people for their service and to use the computational power of the blockchain which is known as gas fee.

1. Now to deploy your contract and to later interact with it, we would need to pay these miners some gas fee. In an actual blockchain, the fee will be paid in real money denominated in the native currency of the blockchain (ETH for Ethereum, BTC for Bitcoin and xDAI for Gnosis). Similarly there is a concept of mock blockchains called testnets, where we can use mock money to pay gas fee (for example Chiado xDAI for Chiado network which is a Gnosis testnet)

2. To pay these gas fee and later interact with our and other contract, we would need something called a wallet. Wallets store private keys, keeping your crypto safe and accessible. They also allow to receive and send assets, some also to interact with smart contracts and dApps.

3. We will be using a wallet called Metamask, which is arguably the most famous crypto wallet out there right now. However you are free to choose any wallet of your liking. 

MetaMask is a web browser extension and mobile app that allows you to manage your Gnosis private keys. By doing so, it serves as a wallet for xDai, GNO and other tokens, and allows you to interact with decentralized applications, or dapps.

Further instructions on how to download and set up your Metamask wallet can be found on the [official Gnosis wiki](https://docs.gnosischain.com/tools/wallets/metamask). I would suggest setting up both the Gnosis mainnet and the Chiado testnet so that you can deploy your smart contracts wherever you like.

4. Now that we have our wallet, we would need some funds to pay as gas fee to deploy our token smart contract and to later interact with it. Gnosis has created faucets for disbursing small amounts of these funds so that people can get started using the chain. To grab your funds, go to the official [Gnosis faucet website](https://gnosisfaucet.com/) and request funds for Chiado testnet (and also the Gnosis mainnet if you want). If things go as expected, you should see a notification like this:

<img width="1728" alt="Screenshot 2022-10-06 at 9 32 59 AM" src="https://user-images.githubusercontent.com/32522659/194211450-a5fe53df-a527-4cda-920f-4cea9cd1209a.png">

On the website you will realise that while you can get `1 Chiado xDAI` from the faucet for the Chiado testnet you only get `0.001 xDAI` from the faucet for the Gnosis maninet. The reason for this as explained above is that the Chiado network is a testnet or a mock blockchain to test your applications, hence the gas fee paid here is also in a mock currency called `Chiado xDAI`. However for the Gnosis mainnet, which is an actual blockchain, you will need to pay the gas fee in real money in terms of a real (crypto) currency called xDAI, and hence the lesser amount.

Post this, you should be able to see the funds in your metamask wallet. Sweet.

## Writing our deployment scripts

0. Create a .env file in the root of your folder.
1. Create the following three entries in the `.env` file:
```shell
CHIADO_RPC_URL='https://rpc.chiadochain.net'
ANVIL_PRIVATE_KEY=
CHIADO_PRIVATE_KEY=
```
2. Inside of `foundry.toml` include the following entry:
```
[rpc_endpoints]
chiado = "${CHIADO_RPC_URL}"
```
3. To grab your `ANVIL_PRIVATE_KEY` open a new tab in your terminal and type in `anvil`. A screen like this should open up:
<img width="1728" alt="anvil" src="https://user-images.githubusercontent.com/32522659/195455910-913ef397-9db8-426b-8c95-fd93c001acce.png">

4. Grab the first private key and paste it in your .env file as your `ANVIL_PRIVATE_KEY`. Your `ANVIL_PRIVATE_KEY` will be used to deploy the scripts locally.

5. To grab the `CHIADO_PRIVATE_KEY`, you have to get the private keys from your Metamask wallet where Chiado network has already been included. To do that follow these steps:

+ Open your Metamask (or whatever wallet you installed) extension and make sure you are on the correct account (one from which you want to deploy the token smart contract).
+ Click on the kebab (three dots) menu
+ Click on Account Details
+ Click on Export Private Key
+ Type your Metamask password
+ Now your private keys are exposed. Copy and paste them somewhere on your system.
    
Your exposed private key window would look something like this (This is for demonstration purposes and this is a throwaway wallet)

![Private Key Metamask](https://0x.games/wp-content/uploads/2021/06/img-2021-06-21-17-30-32.png)

6. A note about private keys: Your private keys are supposed to be private and not meant to be shared with **anyone** under any circumstance. If anyone gets hold of your private keys, they then have unrestricted access to your wallets and all the assets inside it. So, take care and either delete your private keys from your system after this tutorial or simply create a new wallet/account and use that. 

7. Now is the time to write our deployment scripts:

### DeployGovernanceToken

The logic here is to simply deploy the GovernanceTokens contract.
Inside of the `script` folder create a file named `1-DeployGovernanceToken.s.sol` and make sure it includes the following lines of code:

```solidity

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";

contract DeployGovernaneToken is Script {
    GovernanceToken governanceToken;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        {
            governanceToken = new GovernanceToken();
        }
        vm.stopBroadcast();

        console2.log("Governance Token deployed.");
        console2.log("Governance Token deployed at: ", address(governanceToken));

        vm.startBroadcast(deployerPrivateKey);
        {
            governanceToken.delegate(msg.sender);
            uint256 checkpoint = governanceToken.numCheckpoints(msg.sender);
            console2.log("Checkpoint: ", checkpoint);
            assert(checkpoint != 0);
        }
        vm.stopBroadcast();
    }
}


```

Similar to this, create another file called `1-DeployGovernanceToken-Chiado.s.sol` and make sure it includes the following code:

```solidity

// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";

contract DeployGovernanceToken is Script {
    GovernanceToken governanceToken;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("CHIADO_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        {
            governanceToken = new GovernanceToken();
        }
        vm.stopBroadcast();

        console2.log("Governance Token deployed.");
        console2.log("Governance Token deployed at: ", address(governanceToken));

        vm.startBroadcast(deployerPrivateKey);
        {
            governanceToken.delegate(msg.sender);
            uint256 checkpoint = governanceToken.numCheckpoints(msg.sender);
            console2.log("Checkpoint: ", checkpoint);
            assert(checkpoint != 0);
        }
        vm.stopBroadcast();
    }
}

```

Now, to check the correctness of the script, deploy the `GovernanceToken` locally using the following command:

```shell
forge script script/1-DeployGovernanceToken.s.sol --fork-url http://localhost:8545 --broadcast
```

And, once the above script runs successfully, deploy the `GovernanceToken` on the Chiado testnet using the following command:

```shell
forge script script/1-DeployGovernanceToken-Chiado.s.sol:DeployGovernanceToken --rpc-url https://rpc.chiadochain.net --broadcast
```

If things go as expected, you should see a screen like this:
<img width="1728" alt="DeployGovernanceToken-Chiado" src="https://user-images.githubusercontent.com/32522659/195457778-5d5b78bf-6504-4697-b91a-849fe086bbad.png">

## DeployTimeLock

The logic here is also very simple. Deploy the Timelock contract with a minimum delay of 3600 seconds and an empty list of executors and proposors.

Inside of the `script` folder create a file named `2-DeployTimeLock.s.sol` and make sure it includes the following lines of code:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract DeployTimeLock is Script {
    uint256 public constant MIN_DELAY = 3600; // 1 hour
    address[] proposers; // We want to keep this array empty for now
    address[] executors; // We want to keep this array empty for now

    // We basically want only the GovernorContract to be able to propose anything and then anyone can 
    // execute the proposal (after the MIN_DELAY)

    TimeLock timeLock;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        {
            timeLock = new TimeLock(
                MIN_DELAY,
                proposers, //List of proposers
                executors // List of executors
            );
        }
        vm.stopBroadcast();
    }
}
```

Similar to this, create another file called `2-DeployTimeLock-Chiado.s.sol` and make sure it includes the following code:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract DeployTimeLock is Script {
    uint256 public constant MIN_DELAY = 3600; // 1 hour
    address[] proposers; // We want to keep this array empty for now
    address[] executors; // We want to keep this array empty for now

    // We basically want only the GovernorContract to be able to propose anything and then anyone can 
    // execute the proposal (after the MIN_DELAY)

    TimeLock timeLock;
    
    function run() public {
        uint256 deployerPrivateKey = vm.envUint("CHIADO_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        {
            timeLock = new TimeLock(
                MIN_DELAY,
                proposers, //List of proposers
                executors // List of executors
            );
        }
        vm.stopBroadcast();
    }
}
```

Now, to check the correctness of the script, deploy the `TimeLock` contract locally using the following command:

```shell
forge script script/2-DeployTimeLock.s.sol --fork-url http://localhost:8545 --broadcast
```

And, once the above script runs successfully, deploy the `TimeLock` on the Chiado testnet using the following command:

```shell
forge script script/2-DeployTimeLock-Chiado.s.sol:DeployTimeLock --rpc-url https://rpc.chiadochain.net --broadcast 
```

If things go as expected, you should see a screen like this:
<img width="1728" alt="DeployTimeLock-Chiado" src="https://user-images.githubusercontent.com/32522659/195460347-8b2ebd47-38d4-4a31-9c42-0bdefbaffaec.png">


### DeployGovernorContract

The logic here is also very simple. Deploy the Governor contract with quorum percentage as 4, voting delay as 1 and voting period as 5. To grab the address of your `GovernanceToken` and `TimeLock` deployments, head over to `broadcast/1-DeployGovernanceToken/run-latest.json`. There you will see a field `contractAddress` in line number 7 that is the required contract address for the `GovernanceToken`.

Similarly you can find the last deployed address of the `TimeLock` contract by heading over to `broadcast/2-DeployTimeLock/run-latest.json`. 

Inside of the `script` folder create a file named `3-DeployGovernorContract.s.sol` and make sure it includes the following lines of code:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {GovernorContract} from "../src/GovernorContract.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";
import {TimeLock} from "../src/TimeLock.sol";

/**
export const QUORUM_PERCENTAGE = 4 // Need 4% of voters to pass
export const MIN_DELAY = 3600 // 1 hour - after a vote passes, you have 1 hour before you can enact
// export const VOTING_PERIOD = 45818 // 1 week - how long the vote lasts. This is pretty long even for local tests
export const VOTING_PERIOD = 5 // blocks
export const VOTING_DELAY = 1 // 1 Block - How many blocks till a proposal vote becomes active
*/

contract DeployGovernorContract is Script {
    GovernanceToken governanceToken = GovernanceToken(0xa513E6E4b8f2a923D98304ec87F64353C4D5C853);
    TimeLock timeLock = TimeLock(payable(0x8A791620dd6260079BF849Dc5567aDC3F2FdC318));

    GovernorContract governorContract;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        {
            governorContract = new GovernorContract(
                governanceToken,
                timeLock,
                1,
                5,
                4
            );
        }
        vm.stopBroadcast();
    }
}
```
As explained for the local version, for the Chiado version too, if you want to grab the latest deployment address of `GovernanceToken` and/or `TimeLock` you have to head to `broadcast/1-DeployGovernanceToken-Chiado/run-latest.json` (or `broadcast/1-DeployTimeLock-Chiado/run-latest.json`) and grab contract address from line 7. 

You should see a screen like this when grabbing the `GovernanceToken` address:
<img width="1728" alt="GovernanceTokenAddress-Chiado" src="https://user-images.githubusercontent.com/32522659/195461742-ca6868ac-614f-4897-a996-a288acbad598.png">

While, when you grab the `TimeLock` address, you should get a screen like this:
<img width="1728" alt="TimeLockAddress-Chiado" src="https://user-images.githubusercontent.com/32522659/195461785-b229980e-546a-4304-af80-23272c1409dc.png">

Similar to this, create another file called `3-DeployGovernorContract-Chiado.s.sol` and make sure it includes the following code:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {GovernorContract} from "../src/GovernorContract.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";
import {TimeLock} from "../src/TimeLock.sol";

/**
export const QUORUM_PERCENTAGE = 4 // Need 4% of voters to pass
export const MIN_DELAY = 3600 // 1 hour - after a vote passes, you have 1 hour before you can enact
// export const VOTING_PERIOD = 45818 // 1 week - how long the vote lasts. This is pretty long even for local tests
export const VOTING_PERIOD = 5 // blocks
export const VOTING_DELAY = 1 // 1 Block - How many blocks till a proposal vote becomes active
*/

contract DeployGovernorContract is Script {
    GovernanceToken governanceToken = GovernanceToken(0x3b1223B91049644439e27E3aE1E324f428470533);
    TimeLock timeLock = TimeLock(payable(0x834bdCbaAe8b03FaBB1EEe03297fC1e5ee3D1bA8));

    GovernorContract governorContract;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("CHIADO_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        {
            governorContract = new GovernorContract(
                governanceToken,
                timeLock,
                1,
                5,
                4
            );
        }
        vm.stopBroadcast();
    }
}
```

Now, to check the correctness of the script, deploy the `Governor` contract locally using the following command:

```shell
forge script script/3-DeployGovernorContract.s.sol --fork-url http://localhost:8545 --broadcast
```

And, once the above script runs successfully, deploy the `Governor` on the Chiado testnet using the following command:

```shell
forge script script/3-DeployGovernorContract-Chiado.s.sol:DeployGovernorContract --rpc-url https://rpc.chiadochain.net --broadcast
```

If things go as expected, you should see a screen like this:
<img width="1728" alt="deployGovernorContract-Chiado" src="https://user-images.githubusercontent.com/32522659/195460285-31c0ea68-b343-4a26-9dea-4541b68822cb.png">

### SetupGovernanceContracts

The logic here is also very simple. We will use this deployment script to revoke the admin access of ourselves (msg.sender) from the `TimeLock`, assign the `executor` role to address(0), so that anyone can execute the proposals and grant the proposer role to the governor contract so that only the governor can create new proposals.

We already know how to grab the addresses for the current deployments of other contracts by heading over to the broacast folder.

Inside of the `script` folder create a file named `4-SetupGovernanceContracts.s.sol` and make sure it includes the following lines of code:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {GovernorContract} from "../src/GovernorContract.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";
import {TimeLock} from "../src/TimeLock.sol";

/**
export const QUORUM_PERCENTAGE = 4 // Need 4% of voters to pass
export const MIN_DELAY = 3600 // 1 hour - after a vote passes, you have 1 hour before you can enact
// export const VOTING_PERIOD = 45818 // 1 week - how long the vote lasts. This is pretty long even for local tests
export const VOTING_PERIOD = 5 // blocks
export const VOTING_DELAY = 1 // 1 Block - How many blocks till a proposal vote becomes active
*/

contract SetupGovernanceContracts is Script {
    GovernanceToken governanceToken = GovernanceToken(0xa513E6E4b8f2a923D98304ec87F64353C4D5C853);
    TimeLock timeLock = TimeLock(payable(0x8A791620dd6260079BF849Dc5567aDC3F2FdC318));
    GovernorContract governorContract = GovernorContract(payable(0x610178dA211FEF7D417bC0e6FeD39F05609AD788));

    bytes32 proposerAdmin;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        {
            timeLock.grantRole(keccak256("PROPOSER_ROLE"), address(governorContract));
            timeLock.grantRole(keccak256("EXECUTOR_ROLE"), address(0));
            timeLock.revokeRole(keccak256("TIMELOCK_ADMIN_ROLE"), msg.sender);
        }
        vm.stopBroadcast();
    }
}
```
As another example, we already know how to grab the latest deployment addresses of other contracts by navigating to the `broadcast` folder. This is what you'll see when grabbing the `GovernorContract` address:
<img width="1728" alt="GoverorContractAddress-Chiado" src="https://user-images.githubusercontent.com/32522659/195462287-28bb2d0e-7ec0-4e7b-a872-096ded3b1538.png">


Similar to this, create another file called `4-SetupGovernanceContracts-Chiado.s.sol` and make sure it includes the following code:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {GovernorContract} from "../src/GovernorContract.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";
import {TimeLock} from "../src/TimeLock.sol";

/**
export const QUORUM_PERCENTAGE = 4 // Need 4% of voters to pass
export const MIN_DELAY = 3600 // 1 hour - after a vote passes, you have 1 hour before you can enact
// export const VOTING_PERIOD = 45818 // 1 week - how long the vote lasts. This is pretty long even for local tests
export const VOTING_PERIOD = 5 // blocks
export const VOTING_DELAY = 1 // 1 Block - How many blocks till a proposal vote becomes active
*/

contract SetupGovernanceContracts is Script {
    GovernanceToken governanceToken = GovernanceToken(0x3b1223B91049644439e27E3aE1E324f428470533);
    TimeLock timeLock = TimeLock(payable(0x834bdCbaAe8b03FaBB1EEe03297fC1e5ee3D1bA8));
    GovernorContract governorContract = GovernorContract(payable(0x8bfa2AFAC4eb87E8f84AE8B21171ECeB779d387e));

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("CHIADO_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        {
            timeLock.grantRole(keccak256("PROPOSER_ROLE"), address(governorContract));
            timeLock.grantRole(keccak256("EXECUTOR_ROLE"), address(0));
            timeLock.revokeRole(keccak256("TIMELOCK_ADMIN_ROLE"), msg.sender);
        }
        vm.stopBroadcast();
    }
}
```

Now, to check the correctness of the script, make the required changes to the governance contracts locally using the following command:

```shell
forge script script/4-SetupGovernanceContracts.s.sol --fork-url http://localhost:8545 --broadcast
```

And, once the above script runs successfully, make the required changes to the governance contracts on Chiado testnet using the following command:

```shell
forge script script/4-SetupGovernanceContracts-Chiado.s.sol:SetupGovernanceContracts --rpc-url https://rpc.chiadochain.net --broadcast 
```

If things go as expected, you should see a screen like this:
<img width="1728" alt="SetupGovernanceContracts-Chiado" src="https://user-images.githubusercontent.com/32522659/195460376-212d6d05-a85b-47bf-af7a-78f3249e0999.png">


### DeployCollegePresident

The logic here is also very simple. Deploy the CollegePresident contract and then give up the ownership of the contract to the `TimeLock` contract.

Inside of the `script` folder create a file named `5-DeployCollegePresident.s.sol` and make sure it includes the following lines of code:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {CollegePresident} from "../src/CollegePresident.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract DeployCollegePresident is Script {
    CollegePresident collegePresident;
    TimeLock timeLock = TimeLock(payable(0x8A791620dd6260079BF849Dc5567aDC3F2FdC318));

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("ANVIL_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        {
            collegePresident = new CollegePresident();
            // Transfer ownership of CollegePresident contract to Timelock
            collegePresident.transferOwnership(address(timeLock));
        }
        vm.stopBroadcast();
    }
}
```

Similar to this, create another file called `5-DeployCollegePresident-Chiado.s.sol` and make sure it includes the following code:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "../lib/forge-std/src/Script.sol";
import {CollegePresident} from "../src/CollegePresident.sol";
import {TimeLock} from "../src/TimeLock.sol";

contract DeployCollegePresident is Script {
    CollegePresident collegePresident;
        TimeLock timeLock = TimeLock(payable(0x834bdCbaAe8b03FaBB1EEe03297fC1e5ee3D1bA8));

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("CHIADO_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        {
            collegePresident = new CollegePresident();
            // Transfer ownership of CollegePresident contract to Timelock
            collegePresident.transferOwnership(address(timeLock));
        }
        vm.stopBroadcast();
    }
}
```

Now, to check the correctness of the script, deploy the `CollegePresident` contract locally using the following command:

```shell
forge script script/5-DeployCollegePresident.s.sol --fork-url http://localhost:8545 --broadcast 
```

And, once the above script runs successfully, deploy the `CollegePresident` on the Chiado testnet using the following command:

```shell
forge script script/5-DeployCollegePresident-Chiado.s.sol:DeployCollegePresident --rpc-url https://rpc.chiadochain.net --broadcast
```

If things go as expected, you should see a screen like this:
<img width="1728" alt="deployCollegePresident-Chiado" src="https://user-images.githubusercontent.com/32522659/195460240-f60af267-0e6e-4144-9a3d-46836c1c4a76.png">

## Writing Scripts to interact with our contracts

Since we have already covered how to create and integrate a front end with our smart contracts in the earlier tutorial, let's go ahead and write scripts (or tests) to interact with our contracts and see if they indeed do behave as intended or not.

The idea is to write three different test scripts to check whether the `proposing`, `voting` and `execution` functionality works as intended or not.

The `setup` function can be thought of like a cache where whatever you do inside of the `setup` function becomes available to the tests written after it. So, to make our lives easier, we will include:
+ contract deployments and initializations in the proposal setup
+ proposal setup in the voting setup
+ voting setup in the execution setup

### test-dao-proposal

0. Delete all files under the `test` directory and create a new file there called `test-dao-proposal.t.sol`
1. The `.t.sol` extension is used to tell `forge` that this is a test file and should be treated as such.
2. Copy and paste the following code in that file:

```solidity
// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.13;

import "../lib/forge-std/src/Test.sol";
import {IGovernor} from "../lib/openzeppelin-contracts/contracts/governance/IGovernor.sol";
import {GovernanceToken} from "../src/GovernanceToken.sol";
import {TimeLock} from "../src/TimeLock.sol";
import {GovernorContract} from "../src/GovernorContract.sol";
import {CollegePresident} from "../src/CollegePresident.sol";

contract TestDAOProposal is Test {
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

    function setUp() public {
        // Deploying the governanceToken
        governanceToken = new GovernanceToken();
        // Delegating the voting rights to ourselves
        governanceToken.delegate(msg.sender);
        assertTrue(governanceToken.numCheckpoints(msg.sender) != 0);

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
    }

    function test_tokenDeployment() public {
        assertTrue(address(governanceToken)!= address(0));
        assertTrue(address(timeLock) != address(0));
        assertTrue(address(governorContract) != address(0));
        assertTrue(address(collegePresident) != address(0));

        emit log_named_address("GovernanceToken", address(governanceToken));
        emit log_named_address("TimeLock", address(timeLock));
        emit log_named_address("Governor Contract", address(governorContract));
        emit log_named_address("College President", address(collegePresident));
    }

    function test_proposal() public {
        uint proposalID;
        assertEq(proposalID, 0);

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
}
```

3. Save the script and run `forge build --force` to see if everything is working as intended. If everything goes alright, you should see a screen like this:
<img width="926" alt="Screenshot 2022-10-13 at 5 44 42 PM" src="https://user-images.githubusercontent.com/32522659/195593358-b68cb67d-0cd9-4fbb-8dcf-810ffd1adf4c.png">

4. Now, to test the script run this command:
```shell
forge test --match-path test/test-dao-proposal.t.sol -vv
```

If things go as intended, you should see a screen like this:

<img width="1296" alt="Screenshot 2022-10-13 at 5 46 07 PM" src="https://user-images.githubusercontent.com/32522659/195593587-051f4e4f-d238-43de-838b-5c2335394ff2.png">

5. Whatever is happening in this test, is pretty straightforward and explained in the code comments.

### test-dao-voting

0. Create another file `test/test-dao-voting.t.sol`.
1. The `.t.sol` extension is used to tell `forge` that this is a test file and should be treated as such.
2. Copy and paste the following code in that file:
```solidity
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
```
3. Save the script and run `forge build --force` to see if everything is working as intended. If everything goes alright, you should see a screen like this:
<img width="926" alt="Screenshot 2022-10-13 at 5 44 42 PM" src="https://user-images.githubusercontent.com/32522659/195593358-b68cb67d-0cd9-4fbb-8dcf-810ffd1adf4c.png">

4. Now, to test the script run this command:
```shell
forge test --match-path test/test-dao-voting.t.sol -vv
```

If things go as intended, you should see a screen like this:

<img width="1251" alt="Screenshot 2022-10-13 at 5 54 26 PM" src="https://user-images.githubusercontent.com/32522659/195595274-ba9611e1-8d55-4cbd-bb82-f3fc91de5abb.png">

5. Whatever is happening in this test, is pretty straightforward and explained in the code comments.

### test-dao-queue-and-execute

0. Create another file `test/test-dao-queue-and-execute.t.sol`.
1. The `.t.sol` extension is used to tell `forge` that this is a test file and should be treated as such.
2. Copy and paste the following code in that file:
```solidity
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

        //////////////////////////
        // DAO Voting Step
        //////////////////////////
        
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

    function test_queueAndExecute() public {
        //  Now that the proposal has succeded, we need to queue it for the MIN_DELAY and then execute the proposal
        uint256[] memory values = new uint[](1);
        values[0] = 0;

        address[] memory targets = new address[](1);
        targets[0] = address(collegePresident);

        bytes memory makeCollegePresidentCall = abi.encodeWithSelector(collegePresident.makeCollegePresident.selector, "Yami Sukehiro");
        bytes[] memory calldatas = new bytes[](1); 
        calldatas[0] = makeCollegePresidentCall;
        
        uint256 proposalIDFromQueuing = governorContract.queue(
                                            targets, 
                                            values, 
                                            calldatas, 
                                            keccak256(
                                                "Yami Sukehiro always pushes beyond his current limit and inspires his team to do the same. Therefore, he should be the college president"
                                            )
                                        );

        assertEq(proposalID, proposalIDFromQueuing);

        // Since we queued the proposal, the state of the proposal should be Queued
        assertTrue(governorContract.state(proposalID) == IGovernor.ProposalState.Queued);

        // Let's go past the MIN_DELAY (3600 seconds ~= 360 blocks) assuming 1 blocks takes 10 seconds to be minted
        vm.warp(block.timestamp + (MIN_DELAY));
        vm.roll(block.timestamp + (MIN_DELAY));

        // Since we are past the MIN_DELAY, we can execute the proposal
        governorContract.execute(
            targets, 
            values, 
            calldatas, 
            keccak256(
                "Yami Sukehiro always pushes beyond his current limit and inspires his team to do the same. Therefore, he should be the college president"
            )
        );        

        // Now that the proposal has been executed, the state of the proposal should be EXECUTED
        assertTrue(governorContract.state(proposalID) == IGovernor.ProposalState.Executed);

        // Now since the proposal has been executed, our college president should have been updated. Let's check that
        string memory newPresident = collegePresident.getCollegePresident();
        emit log_named_string("New College President", newPresident);

        assertEq(newPresident, "Yami Sukehiro", "Proposal was not executed properly");

        emit log_string("CONGRTULATIONS!! YOU DID IT!! YOU CREATED A DAO, CREATED A PROPOSAL, VOTED AND EXECUTED IT TO ELECT A NEW PRESIDENT");
    }
}
```

3. Save the script and run `forge build --force` to see if everything is working as intended. If everything goes alright, you should see a screen like this:
<img width="926" alt="Screenshot 2022-10-13 at 5 44 42 PM" src="https://user-images.githubusercontent.com/32522659/195593358-b68cb67d-0cd9-4fbb-8dcf-810ffd1adf4c.png">

4. Now, to test the script run this command:
```shell
forge test --match-path test/test-dao-queue-and-execute.t.sol -vv
```

If things go as intended, you should see a screen like this:

<img width="1382" alt="Screenshot 2022-10-13 at 5 56 51 PM" src="https://user-images.githubusercontent.com/32522659/195595746-40989ea4-6176-45c7-8992-d9c7720e05b2.png">

5. Whatever is happening in this test, is pretty straightforward and explained in the code comments.

## Congratulations

You just created a DAO, created governance tokens that can be used to vote, created a proposal, voted on the proposal, queued the proposal and then finally executed the proposal to make a new college president. Well Done!!

### Next Steps:
1. In this tutorial, you were the only DAO member (since you had all the governance tokens). Try and do this exact process but with multiple people holding your governance token.
2. Remember, we also deployed our contracts on chain? You can use the previous tutorial to learn how to hook a front-end to a smart contract and with that you can create a front-end for your smart contract.
3. Instead of votable ERC20, which we used in this tutorial, try implementing this logic with votable ERC721 NFTs.
4. Or just about anything else. Let your imagination, run wild :D
