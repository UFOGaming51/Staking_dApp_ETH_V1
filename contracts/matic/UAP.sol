//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts-upgradeable/token/ERC20/extensions/ERC20BurnableUpgradeable.sol';
import '@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol';

/**
 * @notice Standard UAP token contract mintable only by specific minter
 */
contract UAP is Initializable, ERC20BurnableUpgradeable {
    address public admin; // admin will be a multisig contract address
    address public minter;

    event ChangeMinter(address _newMinter);

    constructor() initializer {}

    function initialize(address _admin, address _minter) public initializer {
        __ERC20_init('UAP', 'UAP');
        admin = _admin;
        minter = _minter;
    }

    function changeMinter(address _newMinter) external {
        require(msg.sender == admin, 'Only admin can change the minter');
        require(minter != _newMinter, 'Old minter and new minter cannot be same');
        minter = _newMinter;
        emit ChangeMinter(_newMinter);
    }

    function mint(address account, uint256 amount) external {
        require(msg.sender == minter, 'Only Minter can mint the token');
        _mint(account, amount);
    }
}
