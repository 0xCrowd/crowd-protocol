// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Pool {
    /*
    */
    address public owner;
    address public initiator;

    event NewDeposit(IERC721 indexed nftAddress, uint indexed nftId, address sender, uint deposit);
    event NewParty(IERC721 indexed nftAddress, uint indexed nftId, uint indexed lastPartyId);
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
        address[] participants;
    }

    struct LotToken {
        uint totalDeposit;
        uint[] parties;
    }

    uint public lastPartyId;
    mapping(uint => Party) public parties;
    // Map pool_id => user address => absolute deposit amount.
    mapping(uint => mapping(address => uint)) shares;
    //mapping(address => mapping(uint => uint)) userTotalInParty;
    mapping(IERC721 => mapping(uint => LotToken)) lotInfo;
    mapping(uint => mapping(address => bool)) isUserInParty;
    mapping(IERC721 => mapping(uint => mapping(address => bool))) isUserInToken;
    // Map users to all DAOs they've ever participated.
    mapping(address => address[]) userToDaos;

    modifier initiatorOnly {require(msg.sender == initiator); _;}

    constructor(address _initiator) {
        owner = msg.sender;
        initiator = _initiator;
    }


    // *** Setter Methods ***
    function setParty(IERC721 _nftAddress, 
                       uint _nftId, 
                       string memory _partyName, 
                       string memory _ticker
                       ) public returns (uint) {
        /*
        Register a new party.
        */
        require(!isUserInToken[_nftAddress][_nftId][msg.sender], 
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
        // Check whether the user is already saved as a participat.
        if (shares[_partyId][msg.sender] == 0) {
            party.participants.push(msg.sender);
        }
        // Update Lot profile.
        LotToken storage lot = nfts[party.nftAddress][party.nftId];
        lot.applicants.update(msg.sender);
        lot.parties.update(_partyId);
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

    // *** Payable Methods ***
    //function returnDeposit() payable {}
    /*
    function distributeDaoTokens(uint _partyId, address _daoAddress, IERC20 _daoToken) public {
        require(parties[_partyId].closed == false, "This pool is closed");
        parties[_partyId].closed = true;
        uint k = _daoToken.totalSupply() / parties[_partyId].total;
        Party storage pool = parties[_partyId];
        Dao dao = Dao(_daoAddress);
        _dao_token.approve(_daoAddress, _daoToken.totalSupply());
        for (uint i = 0; i < pools[_partyId].participants.length; i++) {
            address recipient = pool.participants[i];
            dao.auto_stake(shares[_partyId][recipient]*k, recipient);
            user_to_daos[recipient].push(_daoAddress);
        }
    }
    */

    function get_user_daos(address _user) public returns (address[] memory){
        return userToDaos[_user];
    }

    function get_funds_for_buyout(uint _partyId) public initiatorOnly {
        (bool sent, bytes memory data) = initiator.call{value: _partyId}("");
    }



}