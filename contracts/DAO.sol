// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Pool.sol"
import "./DAOToken.sol"
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";


contract DAO is Initializable {

    // три состояния даю
    // cбор, сбор закончен, сбор отменен
    Pool pool;
    uint goal;
    IERC20Upgradeable dao_token;

    /* 
    There are 3 stages of pool:
    */ 
    enum poolStages{IN_PROGRESS, FULL, FAILED}
    // Every time DAO is created, 
    tages public stage = Stages.IN_PROGRESS;

    function initialize (IERC721Upgradeable _nftAddress,
                uint _nftId, 
                uint _payment, // to create DAO you need to send the first payment
                uint _goal,
                address _creator,
                string memory _name, 
                string memory _ticker,
                uint _daoId) internal initializer {
        
        pool.initialize(_goal, _payment, _creator)
        //
        dao_token = new DAOToken(_name, _ticker, _shares_amount, address(pool));
        name = _name;
        

    function recieve_money(address _user) public payable {

    }
    }
}