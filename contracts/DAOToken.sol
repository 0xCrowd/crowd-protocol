pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DaoToken is ERC20 {
    constructor(string memory _name, string memory _symbol, uint _amount, address _mint_to) ERC20(_name, _symbol) {
        _mint(_mint_to, _amount * 10 ** decimals());
    }
}