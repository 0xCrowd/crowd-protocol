// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract DAOToken is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    function initialize(string memory _name, string memory _symbol,
            uint _amount, address _to) public initializer{
        __ERC20_init(_name, _symbol);
        _mint(_to, _amount * 10 ** decimals());
    }

    function mint(address _to, uint256 _amount) public onlyOwner {
        _mint(_to, _amount);
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
