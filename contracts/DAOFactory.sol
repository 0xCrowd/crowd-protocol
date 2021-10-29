// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DAO.sol";
import "./CRUD.sol";
import "./DAOToken.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";


contract DAOFactory is Initializable, UUPSUpgradeable, OwnableUpgradeable {

    address public initiator;  // Offchain initiator
    uint daoCount;
    CRUD daos; 

    mapping(address => string) daoToCeramic;
    modifier initiatorOnly {require(msg.sender == initiator); _;}

    event NewDao(string name, address indexed dao);
    event NewDeposit(uint daoId, address sender, uint deposit);

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setup(address _new_initiator) public onlyOwner {
        if (_new_initiator != address(0x0)) {
            initiator = _new_initiator;
        }
    }

    // ToDo is it safe to make initial function public?
    function initialize(address _initiator) public initializer {
        //owner = _owner;
        initiator = _initiator;
        daos = new CRUD();
    }

    function new_dao(string memory _DAOname, 
                    string memory _ticker, 
                    uint _shares_amount) public payable returns(address) {
        daoCount++;
        //  Building the brand new DAO.
        DAO dao = new DAO();
        // Create DAO and the pool inside of it.
        dao.initialize(_DAOname, _ticker, _shares_amount);
        dao.recieveDeposit(msg.sender);
        // Send eth to the pool.
        address daoAddr = address(dao);
        // Add dao addres and dao ID to dynamic array.
        daos.create(daoCount, daoAddr);
        emit NewDao(_DAOname, daoAddr);
        return daoAddr;
    }

    function delegateToCeramic(address _daoAddress) public view returns(string memory) {
        return daoToCeramic[_daoAddress];
    }

    function getDao(uint _id) public view returns (address) {
        return daos.read(_id);
    }

    function delDao(uint _id) public initiatorOnly {
        daos.del(_id);
    }

    function getAllDaos() public view returns (CRUD.Instance[] memory){
        return daos.readAll();
    }
}