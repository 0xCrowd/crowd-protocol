// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DAO.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./CRUD.sol";
import "./DAOToken.sol";


contract Factory is Initializable{

    address public initiator;  // Offchain initiator
    address owner;  // Will allow to setup offchain initiator
    uint daoCount;
    CRUD daos = new CRUD();

    mapping(address => string) daoToCeramic;
    modifier ownerOnly {require(msg.sender == owner); _;}
    modifier initiatorOnly {require(msg.sender == initiator); _;}


    event NewDao(string name, address indexed dao);
    event NewDeposit(uint daoId, address sender, uint deposit);

    function setup(address _new_initiator) public ownerOnly {
        if (_new_initiator != address(0x0)) {
            initiator = _new_initiator;
        }
    }

    function initialize(address _owner) public initializer {
        owner = _owner;
    }

    function new_dao(string memory _DAOname, string memory _ticker, string memory _ceramicKey, uint _shares_amount) public payable returns(uint) {
        daoCount++;
        //  Building the brand new DAO.
        DAO dao;
        // Create DAO and the pool inside of it.
        dao.initialize(msg.value, _DAOname, msg.sender, _ticker, daoCount, _shares_amount);
        // Send eth to the pool.
        address daoAddr = address(dao);
        // Map dao address to the specified ceramic key.
        daoToCeramic[daoAddr] = _ceramicKey;
        // Add dao addres and dao ID to dynamic array.
        daos.create(daoCount, daoAddr);
        emit NewDao(_DAOname, daoAddr);
        return daoCount;

    }
    function delegateToCeramic(address _daoAddress) public returns(string memory) {
        return daoToCeramic[_daoAddress];
    }

    function getDao(uint _id) public returns (address) {
        return daos.read(_id);
    }

    function delDao(uint _id) public ownerOnly {
        daos.del(_id);
    }

    function gelAllDaos() public returns (CRUD.Instance[] memory){
        return daos.readAll();
    }
}      