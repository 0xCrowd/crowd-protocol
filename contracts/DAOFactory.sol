// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DAO.sol"
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./CRUD.sol";
import "./DAOToken.sol"


contract Factory is Initializable{

    // mapping(das)
    // that creates the party
    address public initiator;  // Offchain initiator
    address owner;  // Will allow to setup offchain initiator
    uint dao_count;
    CRUD daos = new CRUD();
    // Mapping NFT to daos trying to buy it.
    mapping(IERC721Upgradeable => mapping(uint => uint[])) public nftToDaos;
//  require(userToLotParty[_nftAddress][_nftId][msg.sender] == 0, 
//                                                    "Message sender already participates the payback of the token");
    modifier ownerOnly {require(msg.sender == owner); _;}
    modifier initiatorOnly {require(msg.sender == initiator); _;}


    event NewDao(string name, address indexed dao);


    function setup(address _new_initiator) public ownerOnly {
        if (_new_initiator != address(0x0)) {
            initiator = _new_initiator;
        }
    }
    function new_dao(IERC721Upgradeable _nftAddress,
                uint _nftId, 
                uint _goal,
                string memory _DAOname, 
                string memory _ticker) public payable {
        dao_count++;
        //  Building the brand new DAO.
        Dad dao;
        // Create DAO and the pool inside of it.
        dao.initialize(_nftAddress,_nftId, msg.value, _goal, msg.sender, string memory _DAOname, string memory _ticker);
        // Send eth to the pool.
        dao.pool.setDeposit(msg.sender);
        emit NewDao(_DAOname, address(dao));

    }

    function get_dao(uint _id) public payable returns (bool) {
        return daos.read(_id);
    }
}      