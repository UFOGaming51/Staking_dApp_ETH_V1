//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/token/ERC20/IERC20.sol';
import '../ethereum/StakingFactory.sol';
import '../ethereum/Staking.sol';
import '../ethereum/Plasma.sol';

contract User {
    function approveToken(
        address token,
        address spender,
        uint256 amount
    ) public {
        IERC20(token).approve(spender, amount);
    }

    function transferToken(
        address token,
        address recipient,
        uint256 amount
    ) public {
        IERC20(token).transfer(recipient, amount);
    }

    function stake(Staking staking, uint256 amount) public {
        staking.deposit(amount);
    }

    function unstake(
        Staking staking,
        uint256[] calldata depositNumbers,
        address plasmaRecipient
    ) public {
        staking.withdrawUfoMultiple(depositNumbers, plasmaRecipient);
    }

    function claimVestedReward(Staking staking, uint256[] calldata depositNumbers) public {
        staking.withdrawVestedUfoMultiple(depositNumbers);
    }

    function addMinterToPlasma(Plasma plasma, address minter) public {
        plasma.addMinter(minter);
    }

    function changeUfoPoolPlasmaPerBlock(StakingFactory stakingFactory, uint256 newValue) public {
        stakingFactory.changeUfoPoolPlasmaRewards(newValue);
    }

    function changeLpPoolPlasmaPerBlock(StakingFactory stakingFactory, uint256 newValue) public {
        stakingFactory.changeLpPoolPlasmaRewards(newValue);
    }
}
