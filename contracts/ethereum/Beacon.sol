//SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import '@openzeppelin/contracts/proxy/beacon/IBeacon.sol';
import '@openzeppelin/contracts/access/Ownable.sol';

contract Beacon is IBeacon, Ownable {
    address public impl;

    constructor(address _owner, address _implementation) {
        impl = _implementation;
        transferOwnership(_owner);
    }

    function implementation() external view override returns (address) {
        return impl;
    }

    function upgradeImplementation(address _newImplementation) external onlyOwner {
        impl = _newImplementation;
    }
}
