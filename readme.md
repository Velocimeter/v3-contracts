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
      "contractAddress": "0xE1689e9AaD6b36D91E357FAf95cd7c2C4C1b5475",
      
      "contractName": "GaugeFactoryV2",
      "contractAddress": "0xB9bC49c87920092097e2080a3b91Be674732735F",
      
      "contractName": "BribeFactory",
      "contractAddress": "0x039525b5f1F3aB085BEB522514A7A7b762348531",
     
      "contractName": "PairFactory",
      "contractAddress": "0x42a0B204ae55254CdD10c562F9b101248Ea5DE08",
     
      "contractName": "Router",
      "contractAddress": "0x197b8F8185B84112dD95527ce472A55052cEE030",
      
      "contractName": "VelocimeterLibrary",
      "contractAddress": "0x003b247fC068263BF8b7992dBfa902b827EDB0cF",
     
      "contractName": "VotingEscrow",
      "contractAddress": "0x34172780901eF075C67942392Ab461186d8C8cc5",
      
      "contractName": "RewardsDistributor",
      "contractAddress": "0x82D862D11D4Ff392c1BaeF5502DaA57e99A9E339",
     
      "contractName": "Voter",
      "contractAddress": "0x1E7d4DaFA8E16F90fd5B1220059607fe1f69aA0C",
      
      "contractName": "Minter",
      "contractAddress": "0xCbC293D3fA882A5740A9fCD4670d69FD3f5Fe788",
      
      "contractName": "MintTank",
      "contractAddress": "0xa03360d4841cC8ec726311905E483F1c49d223e3",
          
      "contractName": "OptionTokenV2",
      "contractAddress": "0xfEFBC02930D389E624B56053E345Cd848729BF93",
     
      "contractName": "AirdropClaim",
      "contractAddress": "0xA9f15E51C825410737e9793eaC9091dD22D866DB",
          
      

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
      