// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./util_libs/AddressSet.sol";
import "./util_libs/UintSet.sol";

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Pool {
    /*
    Grouping all data types that are supposed to go together into one 32 byte slot, and declare them one after
    another in your code. It is important to group data types together as the EVM stores the variables 
    one after another in the given order. This is only done for state variables and inside of structs. 
    Arrays consist of only one data type, so there is no ordering necessary.
    */
    address public owner;
    address public initiator;

    using AddressSet for AddressSet.Set;
    using UintSet for UintSet.Set;
    

    constructor(address _initiator){
        owner = msg.sender;
        initiator = _initiator;

        // hardcoded for now
    }

    //AddressSet.Set userSet;
    //AddressSet.Set nftSet;
    //UintSet.Set partySet;
    event NewDeposit(IERC721 indexed nftAddress, uint indexed nftId, address sender, uint deposit);
    event NewParty(IERC721 indexed nftAddress, uint indexed nftId, uint indexed pool_id);
    event PoolEnd(IERC721 indexed nftAddress, uint nftId, address sender);
    // If all participants took they ETH back from the party.
    event PoolForcedEnd(IERC721 indexed nftAddress, uint nftId, address sender);

    struct Party {
        string partyName;
        address creator;
        string ticker;
        IERC721 nftAddress;
        uint nftId;
        uint totalDeposit;
        bool isClosed;
    }

    struct User {
        uint totalDeposit;
        mapping(uint => uint) partyToAmount;
        address[] daosHistory;
    }

    struct LotToken {
        AddressSet.Set applicants;
        UintSet.Set parties;
    }

    uint public lastPartyId;
    mapping(uint => Party) parties;
    mapping(uint => AddressSet.Set) partyParticipants;
    mapping(address => User) users;
    mapping(IERC721 => mapping(uint => LotToken)) nfts;

    // *** Setter Methods ***
    function setParty(IERC721 _nftAddress, 
                       uint _nftId, 
                       string memory _partyName, 
                       string memory _ticker
                       ) public returns (uint) {
        /*
        Create a new party.
        */
        require(!nfts[_nftAddress][_nftId].applicants.exists(msg.sender), 
                                                    "Message sender already participates the payback of the token");
        lastPartyId++;
        Party storage party = parties[lastPartyId];
        party.partyName = _partyName;
        party.creator = msg.sender;
        party.ticker = _ticker;
        party.nftAddress = _nftAddress;
        party.nftId = _nftId;
        party.totalDeposit = 0;
        party.isClosed = false;

        emit NewParty(_nftAddress, _nftId, lastPartyId);
        return lastPartyId;
    }

    function setDeposit(uint _partyId) public payable {
        /*
        Receive the payment and update the pool statistics.
        */
        require(_partyId <= lastPartyId, "This party doesn't exist");
        require(parties[_partyId].isClosed == false, "This pool is closed");
        // Update Party profile.
        Party storage party = parties[_partyId];
        party.totalDeposit += msg.value;
        // Update Party - Participants mapping.
        partyParticipants[_partyId].update(msg.sender);
        // Update User profile.
        User storage user = users[msg.sender];
        user.totalDeposit += msg.value;
        user.partyToAmount[_partyId] += msg.value;
        // Update Lot profile.
        LotToken storage lot = nfts[party.nftAddress][party.nftId];
        lot.applicants.update(msg.sender);
        lot.parties.update(_partyId);
        //
        emit NewDeposit(party.nftAddress, party.nftId, msg.sender, msg.value);
    }

    // *** Getter Methods ***
    function getPartyDescription(uint _party_id) public view returns (string memory, string memory) {
        return (parties[_party_id].partyName, parties[_party_id].ticker);
    }

    function getParty(uint _party_id) public view returns (Party memory) {
        return parties[_party_id];
    }

    function getUserPartyStatus(uint _party_id, address _user) public view returns (bool) {
        /*
        Check whether the user already participantes the party.
        */
        return partyParticipants[_party_id].exists(_user);
    }

    function getTotalUserDeposit(uint _party_id, address _user) public view returns (uint) {
        /*
        Get the absolute amount of WEI deposited by the specified user to the target `IERC721` token.
        */
        return users[_user].partyToAmount[_party_id];
    }

    function getTotalTokenDeposit(uint _pool_id) public view returns (uint) {
        /*
        Get the total deposit sum for the Party.
        */
        return parties[_pool_id].totalDeposit;
    }

    // *** Payable Methods ***
    //function returnDeposit(){}

    // *** Delete Methods ***
    //funtion delParty()

}