// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Pool.sol"
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";


contract DAO is Initializable {

    // три состояния даю
    // cбор, сбор закончен, сбор отменен
    Pool pool = new Pool();
    uint goal;
    IERC20Upgradeable dao_token;

    /* 
    There are 3 stages of pool:
    */ 
    enum poolStages{IN_PROGRESS, FULL, FAILED}
    // Every time DAO is created, 
    tages public stage = Stages.IN_PROGRESS;

    function initialize (string memory _name,
                IERC20Upgradeable _dao_token,
                IERC721Upgradeable _nftAddress,
                uint _nftId, 
                uint payment, // to create DAO you need to send the first payment
                uint goal,
                address creator,
                string memory _partyName, 
                string memory _ticker) public initializer {
        
        pool.initialize()
        name = _name;
        dao_token = _dao_token;

    function recieve_money(address _user) public payable {

    }


        
    }
}