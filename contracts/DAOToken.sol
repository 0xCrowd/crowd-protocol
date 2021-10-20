pragma solidity ^0.8.0;
import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";

contract DaoToken is ERC20Upgradeable, Initializable {
    //function initialize()
    function initialize(string memory _name, string memory _symbol, uint _amount, address _mint_to) {
        __ERC20Upgradeable_init_unchained();
        _mint(_mint_to, _amount * 10 ** decimals());
    }
}