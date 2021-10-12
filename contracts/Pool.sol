pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract PoolInterface{
    function setParty(IERC721 _nft_address, uint _nft_id, string memory _party_name, string memory _ticker) public returns (uint) {}
    function setDeposit(uint _pool_id) public payable {}   
    function getPartyDescription(uint _pool_id) public view returns (string memory, string memory) {}
    function getParty(uint _pool_id) public view returns (Party memory) {}
    function getUserPartyStatus(uint _pool_id, address _user) public view returns (bool) {}
    function getTotalUserDeposit(uint _pool_id, address _user) public view returns (uint) {}
    function getTotalTokenDeposit(uint _pool_id) public view returns (uint) {}
    function returnDeposit(){}

    event NewDeposit(IERC721 indexed nft_address, uint indexed nft_id, address sender, uint deposit);
    event NewParty(IERC721 indexed nft_address, uint indexed nft_id, uint indexed pool_id);
    event PoolEnd(IERC721 indexed nft_address, uint nft_id, address sender);
    // If all participants took they ETH back from the party.
    event PoolForcedEnd(IERC721 indexed nft_address, uint nft_id, address sender);

}

// TODO: use safe math, rename variables, implement safe eth transfer

contract Pool{
    /*
    Grouping all data types that are supposed to go together into one 32 byte slot, and declare them one after
    another in your code. It is important to group data types together as the EVM stores the variables 
    one after another in the given order. This is only done for state variables and inside of structs. 
    Arrays consist of only one data type, so there is no ordering necessary.
    */
    address public owner;
    address public initiator;

    struct Party {
        /*
        Describes the properties of the Party entity.
        */
        string party_name;
        string ticker;
        // Store the account address.
        IERC721 nft_address;
        // Store the ID of the token.
        uint nft_id;
        // Store the total deposited sum.
        uint total;
        // Track whether the acquisition process is already closed.
        bool closed;
        // Store the array of all unique participanting addresses.
        address[] participants;
    }
    uint public lastPartyId;
    mapping(uint => Party) parties;


    constructor(address _initiator){
        owner = msg.sender;
        initiator = _initiator;  // hardcoded for now
    }

    modifier openedOnly(uint _pool_id) {
        require(pools[_pool_id].closed == false, "This pool is closed");
        _;
    }

    // *** Setter Methods ***
    function setParty(IERC721 _nft_address, 
                       uint _nft_id, 
                       string memory _party_name, 
                       string memory _ticker
                       ) public returns (uint) {
        /*
        Create a new party.
        */
        require(pool_id_by_nft[_nft_address][_nft_id] == 0, "This NFT is already under the party");
        lastPartyId += 1;
        address[] memory empty;
        Party memory party = Party(_party_name, _ticker, _nft_address, _nft_id, 0, false, empty);
        parties[lastPartyId] = party;
        emit NewParty(_nft_address, _nft_id, lastPartyId);
        return lastPartyId;
    }

    function setDeposit(uint _pool_id) public payable {
        /*
        Receive the payment and update the pool statistics.
        */
        require(_pool_id <= pool_id, "This pools doesn't exist");
        require(pools[pool_id].closed == false, "This pool is closed");
        if (participant_in_pool[pool_id][msg.sender] != true) {
            pools[pool_id].participants.push(msg.sender);
            participant_in_pool[pool_id][msg.sender] = true;
        }
        shares[_pool_id][msg.sender] += msg.value;
        pools[pool_id].total += msg.value;  
        emit NewDeposit(pools[pool_id].nft_address, pools[pool_id].nft_id, msg.sender, msg.value);
    }

    // *** Getter Methods ***
    function getPartyDescription(uint _pool_id) public view returns (string memory, string memory) {
        return (parties[_pool_id].party_name, parties[_pool_id].ticker);
    }

    function getParty(uint _pool_id) public view returns (Party memory) {
        return parties[_pool_id];
    }

    function getUserPartyStatus(uint _pool_id, address _user) public view returns (bool) {
        /*
        Check whether the user already participantes the party.
        */
        return participant_in_pool[_pool_id][_user];
    }

    function getTotalUserDeposit(uint _pool_id, address _user) public view returns (uint) {
        /*
        Get the absolute amount of WEI deposited by the specified user to the target `IERC721` token.
        */
        return shares[_pool_id][_user];
    }

    function getTotalTokenDeposit(uint _pool_id) public view returns (uint) {
        /*
        Get the total deposit sum for the target `IERC721` token.
        */
        return parties[_pool_id].total;
    }

    function returnDeposit(){}
}