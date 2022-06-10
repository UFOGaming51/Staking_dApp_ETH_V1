import { BigNumber } from '@ethersproject/bignumber';

export const mainnet = {
    uniswapFactoryAddress: '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f',
    uniswapV2Router02: '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D',
    tokenCreationConstants: {
        name: 'X Token',
        symbol: 'XT',
        init_supply: BigNumber.from(1).mul(BigNumber.from(10).pow(23)),
    },
    Contracts: {
        DAI: '0x6B175474E89094C44Da98b954EedeAC495271d0F',
        LINK: '0x514910771AF9Ca656af840dff83E8264EcF986CA',
    },
    vrfKeyHash: '0xAA77729D3466CA35AE8D28B3BBAC7CC36A5031EFDC430821C02BC31A238AF445',
    Whale: {
        DAI: '0x47ac0Fb4F2D84898e4D9E7b4DaB3C24507a6D503',
        LINK: '0xF977814e90dA44bFA03b6295A0616a897441aceC',
    },
    testingAmountForDeposit: BigNumber.from(100).mul(BigNumber.from(10).pow(18)),
};

export const matic_mumbai = {
    Contracts: {
        LINK: '0x326C977E6efc84E512bB9C30f76E30c160eD06FB',
        VRF_Cordinator: '0x8C7382F9D8f56b33781fE506E897a4F1e2d17255',
    },
    vrfKeyHash: '0x6e75b569a01ef56d18cab6a8e71e6600d6ce853834d4a5748b720d06f878b3a4',
};

export const goerli = {
    uniswapFactoryAddress: '0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f',
    uniswapV2Router02: '0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D',
};

export const zeroAddress = '0x0000000000000000000000000000000000000000';
