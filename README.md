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
forge script script/DeployGovernanceToken.s.sol --fork-url http://localhost:8545 --broadcast
```

And, once the above script runs successfully, deploy the `GovernanceToken` on the Chiado testnet using the following command:

```shell
forge script script/1-DeployGovernanceToken-Chiado.s.sol:DeployGovernanceToken --rpc-url https://rpc.chiadochain.net --broadcast
```

If things go as expected, you should see a screen like this:
<img width="1728" alt="DeployGovernanceToken-Chiado" src="https://user-images.githubusercontent.com/32522659/195457778-5d5b78bf-6504-4697-b91a-849fe086bbad.png">
