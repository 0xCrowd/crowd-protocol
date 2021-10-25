// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DAO.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "./CRUD.sol";
import "./DAOToken.sol";


contract DAOFactory is Initializable{

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

    // ToDo constructor is added to support non-upgradable deploy
    constructor(address _owner, address _initiator) {
        owner = _owner;
        initiator = _initiator;
    }

    // ToDo is it safe to make initial function public?
    function initialize(address _owner, address _initiator) public initializer {
        owner = _owner;
        initiator = _initiator;
    }

    function new_dao(string memory _DAOname, string memory _ticker, uint _shares_amount) public payable returns(address) {
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