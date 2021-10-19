// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CRUD.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Pool is Initializable {
    /*
    */
    using SafeMath for uint;
    
    address private owner;
    address public initiator;
    uint public lastPartyId;

    struct Party {
        string partyName;
        address creator;
        string ticker;
        IERC721Upgradeable nftAddress;
        uint nftId;
        uint totalDeposit;
        bool isClosed;
        address[] participants;
    }

    CRUD crud = new CRUD();
    mapping(uint => Party) public parties;
    // Map pool_id => user address => absolute deposit amount.
    mapping(uint => mapping(address => uint)) public shares;
    //mapping(address => mapping(uint => uint)) userTotalInParty;
    //mapping(uint => mapping(address => bool)) isUserInLotParty;
    mapping(IERC721Upgradeable => mapping(uint => mapping(address => uint))) public userToLotParty;
    // Map users to all DAOs they've ever participated.
    mapping(address => address[]) public userToDaos;
    
    event NewDeposit(IERC721Upgradeable indexed nftAddress, uint indexed nftId, address sender, uint deposit);
    event NewParty(IERC721Upgradeable indexed nftAddress, uint indexed nftId, uint indexed lastPartyId);
    event PoolEnd(IERC721Upgradeable indexed nftAddress, uint nftId, address sender);
    // If all participants took they ETH back from the party.
    event PoolForcedEnd(IERC721Upgradeable indexed nftAddress, uint nftId, address sender);

    modifier initiatorOnly {
        require(msg.sender == initiator); _;}
    
    function initialize(address _initiator) public initializer {
        owner = msg.sender;
        initiator = _initiator;

    }

    // *** Setter Methods ***
    function setParty(IERC721Upgradeable _nftAddress, 
                       uint _nftId, 
                       string memory _partyName, 
                       string memory _ticker
                       ) public returns (uint) {
        /*
        Register a new party.
        */
        require(userToLotParty[_nftAddress][_nftId][msg.sender] == 0, 
                                                    "Message sender already participates the payback of the token");
        lastPartyId++;
        Party storage party = parties[lastPartyId];
        address[] memory empty;
        party.partyName = _partyName;
        party.creator = msg.sender;
        party.ticker = _ticker;
        party.nftAddress = _nftAddress;
        party.nftId = _nftId;
        party.totalDeposit = 0;
        party.isClosed = false;
        party.participants = empty;
        // Add party to the index.
        crud.create(true, lastPartyId);
        emit NewParty(_nftAddress, _nftId, lastPartyId);
        return lastPartyId;
    }

    function setDeposit(uint _partyId) public payable {
        /*
        Receive the payment and update the pool statistics.
        */
        require(_partyId <= lastPartyId, "This party doesn't exist");
        require(parties[_partyId].isClosed == false, "This pool is closed");
        //
        Party storage party = parties[_partyId];
        uint userTokenParty = userToLotParty[party.nftAddress][party.nftId][msg.sender];
        // Check whether the user already tries to but the token as a memeber of a different party. 
        if (userTokenParty == 0) {
            userTokenParty = _partyId;
            // Store user address as a participant.
            party.participants.push(msg.sender);
        } else {
            require(userTokenParty == _partyId, "Message sender already participates the payback of the token");
        }
        userToLotParty[party.nftAddress][party.nftId][msg.sender] = userTokenParty;
        party.totalDeposit = party.totalDeposit.add(msg.value);
        //
        shares[_partyId][msg.sender] = shares[_partyId][msg.sender].add(msg.value);
        //
        emit NewDeposit(party.nftAddress, party.nftId, msg.sender, msg.value);
    }

    // *** Getter Methods ***
    function getPartyDescription(uint _partyId) external view returns (string memory, string memory) {
        return (parties[_partyId].partyName, parties[_partyId].ticker);
    }

    function getParty(uint _party_id) external view returns (Party memory) {
        return parties[_party_id];
    }

    function getUserPartyStatus(uint _partyId, address _user) external view returns (bool) {
        /*
        Check whether the user already participantes the party.
        */
        return (shares[_partyId][_user] != 0);
    }

    function getTotalUserDeposit(uint _partyId, address _user) external view returns (uint) {
        /*
        Get the absolute amount of WEI deposited by the specified user to the target `IERC721` token.
        */
        return shares[_partyId][_user];
    }

    function getTotalTokenDeposit(uint _partyId) external view returns (uint) {
        /*
        Get the total deposit sum for the Party.
        */
        return parties[_partyId].totalDeposit;
    }

    function getUserDaos(address _user) public view returns (address[] memory) {
        return userToDaos[_user];
    }
    
    function getActiveParties() public view returns (CRUD.Instance[] memory){
        return crud.readAll();
    }
    
    function getBalance() public view returns (uint) {
        return address(this).balance;
    }

    // *** Money Transfer Methods ***

    function getFundsForBuyout(uint _partyId) public initiatorOnly returns (bool sent, bytes memory data){
        // Error: Avoid to use low level calls.
        (sent, data) = initiator.call{value: _partyId}("");
        return (sent, data);
    }

    function returnDeposit(uint _partyId, uint _amount) public payable initiatorOnly {
        /*
        */
        uint userTotal = shares[_partyId][initiator];
        uint withdrawAmount;
        if (userTotal < _amount) { 
            withdrawAmount = userTotal;
        } else {
            withdrawAmount = _amount;
            }
        updateStatsAndTransfer(_partyId, initiator, withdrawAmount);
    }

    function updateStatsAndTransfer(uint _partyId, address _user, uint _amount) public payable initiatorOnly {
        /*
        */
        Party storage party  = parties[_partyId];
        //
        shares[_partyId][_user] = shares[_partyId][_user].sub(_amount);
        //
        party.totalDeposit = party.totalDeposit.sub(_amount);
        //
        userToLotParty[party.nftAddress][party.nftId][_user] = userToLotParty[party.nftAddress][party.nftId][_user].sub(_amount);
        // Workaround, should be refactored.
        if (parties[_partyId].totalDeposit <= 0) {
            crud.del(_partyId);
            parties[_partyId].isClosed = true;
        }
        payable(_user).transfer(_amount);
    }

    /*
    // Uncomment this function after creating asset storage.

    function distributeDaoTokens(uint _partyId, address _daoAddress, IERC20Upgradeable _daoToken) public {
        require(parties[_partyId].closed == false, "This pool is closed");
        parties[_partyId].isClosed = true;
        uint k = _daoToken.totalSupply() / parties[_partyId].totalDeposit;
        Party storage party = parties[_partyId];
        Dao dao = Dao(_dasssoAddress);
        _daoToken.approve(_daoAddress, _daoToken.totalSupply());
        for (uint i = 0; i < parties[_partyId].participants.length; i++) {
            address recipient = party.participants[i];
            dao.auto_stake(shares[_partyId][recipient]*k, recipient);
            userToDaos[recipient].push(_daoAddress);
        }
    }
    */


}