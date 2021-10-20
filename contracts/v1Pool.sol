// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CRUD.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";

contract Pool is Initializable {
    /*
    */    
    address private owner;
    address public initiator;
    uint public goal;
    uint public total;


    // Map pool_id => user address => absolute deposit amount.
    mapping(address => uint) public shares;


    event NewDeposit(IERC721Upgradeable indexed nftAddress, uint indexed nftId, address sender, uint deposit);

    modifier initiatorOnly {
        require(msg.sender == initiator); _;}
    
    function initialize(address _owner, address _user, uint _payment, uint _goal) internal initializer {
        owner = _owner;
        goal = _goal;
        }
    //function initiate(address _initiator) public {initiator = _initiator;}

    // *** Setter Methods ***

    function setDeposit(address _user) public payable {
        /*
        Receive the payment and update the pool statistics.
        */
        require(total+msg.value <= goal, "The deposit is too big");
        totalDeposit += msg.value;
        shares[_user] += msg.value;
        //
        emit NewDeposit(party.nftAddress, party.nftId, _user, msg.value);
    }

    // *** Getter Methods ***
    function getTotalUserDeposit(uint _partyId, address _user) external view returns (uint) {
        /*
        Get the absolute amount of WEI deposited by the specified user to the target `IERC721` token.
        */
        return shares[_user];
    }

    function getTotalDeposit(uint _partyId) external view returns (uint) {
        /*
        Get the total deposit sum for the Party.
        */
        return total;
    }

    // *** Money Transfer Methods ***
    /*
    function getFundsForBuyout(uint _partyId) public initiatorOnly returns (bool sent, bytes memory data){
        // Error: Avoid to use low level calls.
        (sent, data) = initiator.call{value: _partyId}("");
        return (sent, data);
    }*/

    function returnExtraMoney(address _message_sender, uint _amount) internal {

    }

    function returnDeposit(address _message_sender, uint _amount) public  {
        /*
        */
        uint userTotal = shares[_message_sender];
        require(userTotal > 0, "This user does not participate the party")
        uint withdrawAmount;
        if (userTotal < _amount) { 
            withdrawAmount = userTotal;
        } else {
            withdrawAmount = _amount;
            }
        updateStatsAndTransfer(_partyId, initiator, withdrawAmount);
    }

    function updateStatsAndTransfer(address _message_sender, uint _amount) private {
        /*
        */
        //
        shares[_message_sender] -= _amount;
        //
        public -= _amount;
        //
        payable(_message_sender).transfer(_amount);
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