# Velocimeter

This repo contains the contracts for Velocimeter Finance, an AMM on Canto inspired by Solidly.

## Testing

This repo uses both Foundry (for Solidity testing) and Hardhat (for deployment).

Foundry Setup

```ml
forge init
forge build
forge test
```

Hardhat Setup

```ml
npm i
npx hardhat compile
```

## Deployment

This project's deployment process uses [Hardhat tasks](https://hardhat.org/guides/create-task.html). The scripts are found in `tasks/`.

Deployment contains 3 steps:

1. `npx hardhat deploy:op` which deploys the core contracts to Optimism.

## Security

The Velodrome team engaged with Code 4rena for a security review. The results of that audit are available [here](https://code4rena.com/reports/2022-05-velodrome/). Our up-to-date security findings are located on our website [here](https://docs.velodrome.finance/security).

## Contracts on Fantom

      "contractName": "Flow",
      "contractAddress": "0x39b9D781dAD0810D07E24426c876217218Ad353D",
      
      "contractName": "GaugeFactory",
      "contractAddress": "0x0a59A1160B54B94c7FF130d225E9f3f6DE51545b",
      
      "contractName": "BribeFactory",
      "contractAddress": "0xBB7457a05E29B26Eb6Fa6Cb307C8f86f630016a4",
     
      "contractName": "PairFactory",
      "contractAddress": "0x6B4449C74a9aF269A5f72B88B2B7B8604685D9B9",
     
      "contractName": "Router",
      "contractAddress": "0x370d160992C8C48BCCFcf009f0c9db9d00574eF7",
      
      "contractName": "VelocimeterLibrary",
      "contractAddress": "0xD5aa5eFe3bEC2e4646F6e2414b4a8DF44233D7B7",
      
      "contractName": "VeArtProxy",
      "contractAddress": "0x087CDf0b09562caFe7b5B5f52c343117d0A847e1",
     
      "contractName": "VotingEscrow",
      "contractAddress": "0xe7b8F4D74B7a7b681205d6A3D231d37d472d4986",
      
      "contractName": "RewardsDistributor",
      "contractAddress": "0x582aEB28632800467C7F672375fE57baB15822a5",
     
      "contractName": "Voter",
      "contractAddress": "0x8C4FF4004c8a85054639B86E9F8c26e9DA7ff738",
     
      "contractName": "Minter",
      "contractAddress": "0x1D84F65DAe4bf9298be27d62cB06A3b32f79fDCC",
     
      "contractName": "MintTank",
      "contractAddress": "0xbB7bbd0496c23B7704213D6dbbe5C39eF8584E45",
     
      "contractName": "OptionToken",
      "contractAddress": "0x1Fc0A9f06B6E85F023944e74F70693Ac03fDC621",

      "contractName": "AirdropClaim",
      "contractAddress": "0x3339ab188839C31a9763352A5a0B7Fb05876BC44",
      

## Contracts on Pulse

      "contractName": "Flow",
      "contractAddress": "0x39b9D781dAD0810D07E24426c876217218Ad353D",

      "contractName": "GaugeFactory",
      "contractAddress": "0x0a59A1160B54B94c7FF130d225E9f3f6DE51545b",
   
      "contractName": "BribeFactory",
      "contractAddress": "0xBB7457a05E29B26Eb6Fa6Cb307C8f86f630016a4",
      
      "contractName": "PairFactory",
      "contractAddress": "0x6B4449C74a9aF269A5f72B88B2B7B8604685D9B9",
      
      "contractName": "Router",
      "contractAddress": "0x370d160992C8C48BCCFcf009f0c9db9d00574eF7",
      
      "contractName": "VelocimeterLibrary",
      "contractAddress": "0xD5aa5eFe3bEC2e4646F6e2414b4a8DF44233D7B7",
     
      "contractName": "VeArtProxy",
      "contractAddress": "0x087CDf0b09562caFe7b5B5f52c343117d0A847e1",
    
      "contractName": "VotingEscrow",
      "contractAddress": "0xe7b8F4D74B7a7b681205d6A3D231d37d472d4986",
      
      "contractName": "RewardsDistributor",
      "contractAddress": "0x582aEB28632800467C7F672375fE57baB15822a5",
      
      "contractName": "Voter",
      "contractAddress": "0x8C4FF4004c8a85054639B86E9F8c26e9DA7ff738",
      
      "contractName": "Minter",
      "contractAddress": "0x1D84F65DAe4bf9298be27d62cB06A3b32f79fDCC",
      
      "contractName": "MintTank",
      "contractAddress": "0xbB7bbd0496c23B7704213D6dbbe5C39eF8584E45",
     
      "contractName": "OptionToken",
      "contractAddress": "0x1Fc0A9f06B6E85F023944e74F70693Ac03fDC621",
      