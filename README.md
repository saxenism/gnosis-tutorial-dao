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

contract CollegePresident {
    string private collegePresident;

    event CollegePresidentChanged(string president);

    function makeCollegePresident(string memory president) public {
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
  ) TimelockController(minDelay, proposers, executors, address(0)) {
    
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

## Writing our deployment scripts

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

## Deploying our smart contract

0. Make sure that your Token contract is compiling without any issues by using the following command:

```shell

forge build

```

If things went as expected, you should see something like this:

<img width="1728" alt="Screenshot 2022-10-05 at 5 40 16 PM" src="https://user-images.githubusercontent.com/32522659/194212564-4f1f90f1-3e11-4997-8704-ee6a40bf8521.png">

1. Now we need to grab our private keys in order to deploy our token smart contract. 

    + Open your Metamask (or whatever wallet you installed) extension and make sure you are on the correct account (one from which you want to deploy the token smart contract).
    + Click on the kebab (three dots) menu
    + Click on Account Details
    + Click on Export Private Key
    + Type your Metamask password
    + Now your private keys are exposed. Copy and paste them somewhere on your system.
    
Your exposed private key window would look something like this (This is for demonstration purposes and this is a throwaway wallet)

![Private Key Metamask](https://0x.games/wp-content/uploads/2021/06/img-2021-06-21-17-30-32.png)

2. A note about private keys: Your private keys are supposed to be private and not meant to be shared with **anyone** under any circumstance. If anyone gets hold of your private keys, they then have unrestricted access to your wallets and all the assets inside it. So, take care and either delete your private keys from your system after this tutorial or simply create a new wallet/account and use that. 

3. Once you do have your private keys, its time to use them to deploy your token smart contract to either the Chiado testnet or the Gnosis mainnet. The command to deploy that is as follows:

In our case, the first placeholder <YourContract> would be replaced by `Token` and the second <YourContract> placeholder will be replaced by `TestToken` and the <your_private_key> will be replaced by whatever we grabbed in step 1 of this section.

+ For Chiado testnet
```shell

forge create --rpc-url https://rpc.chiadochain.net --private-key <your_private_key> src/<YourContract>.sol:<YourContract>

```

+ For Gnosis mainnet
```shell

forge create --rpc-url https://rpc.gnosischain.com --private-key <your_private_key> src/<YourContract>.sol:<YourContract>

```

If things go as expected, you should see a screen similar to this:

<img width="1728" alt="deploy-success" src="https://user-images.githubusercontent.com/32522659/194214389-dfdf4697-04b9-4b6f-89f4-b0f8a33d17e3.png">

4. Congratulations!! You just deployed your tokens on the Chiado testnet (or the gnosis mainnet) and the address of your tokens (or token contract) is the address written infront of the `deployed to` spec in the earlier image.

5. You can also see the deployment done by you (your wallet) on the Gnosis/Chiado block explorer. For this you need to visit the official [Chiado explorer](https://blockscout.chiadochain.net/) or [Gnosis explorer](https://gnosisscan.io/) depending on where you deployed and search for your wallet address. In the page that opens up, you should see a deployment done by you, something like this:
    
    <img width="1728" alt="Screenshot 2022-10-05 at 5 13 24 PM" src="https://user-images.githubusercontent.com/32522659/194222864-3c57b1b8-3584-410a-91b6-16c67a16c2bb.png">
    
6. Remember the code that we wrote in `Token.sol` ? There we minted 1000 `TTG` tokens to the msg.sender (which is our deploying wallet in this case), so we should be able to see those 1000 tokens in our wallet, right? We need to include our token in our wallets for that to happen. The steps to do that are as follows:
    + Click on your Metamask wallet extension
    + Make sure you are on the correct account and correct network
    + Click on the `Import Tokens` option
    + In the `Token Contract Address` fill the address where your token contract was deployed to
    + Other fields should get autofilled (if not, fill the name and decimals which was 18 by default)
    + Click on `Add Custom Token`
    + Now you should be able to see your token in your wallet
    + Congratulations!! Now you can send and recieve your tokens to and from your friends using your Metamask wallet.
    
If things went as expected, you should see something like this:
    
<img width="1728" alt="Screenshot 2022-10-05 at 5 19 41 PM" src="https://user-images.githubusercontent.com/32522659/194227648-7a96ae5a-2d36-4506-b870-8a4cc28250d3.png">

