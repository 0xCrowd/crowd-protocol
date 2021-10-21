// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DAOToken.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract DAO is Initializable, IERC721Receiver {
    /* 
    Right now there are 2 stages of funding process:
    */ 
    // cбор, сбор закончен, сбор отменен
    enum Stages{ IN_PROGRESS, FULL }

    struct AssetERC20 {
        address addr;  // Address of stored asset ERC20
    }

    struct Vault {
        mapping(address => bool) asset_locked;
        mapping(address => uint) userToEth;
        AssetERC20[] erc20;  // Locked ERC20
    }

    Vault vault;
    address owner;
    Stages public stage = Stages.IN_PROGRESS;
    uint goal;
    ERC20 dao_token;

    modifier onlyFull() { require(stage ==  Stages.FULL); _; }
    modifier transitionAfter() { _; nextStage(); }

    function initialize (uint _payment, 
                string memory _name, 
                address _user,
                string memory _ticker,
                uint _daoId,
                uint _shares_amount) public payable initializer {
        // Get DAO token.
        owner = msg.sender; // Should be Factory?
        dao_token = new DAOToken(
                _name,
                _ticker,
                _shares_amount,  // ToDo initialize: We should discuss the amount of minted shares.
                address(this));
        vault.userToEth[_user] += _payment; 
    }

    function getDeposit(address _user) public payable {}

    function stake(uint _amount, address stake_for,address _user) public onlyFull {
        if (dao_token.allowance(_user, address(this)) < _amount) {
            dao_token.approve(address(this), _amount);
        }
        dao_token.transferFrom(_user, address(this), _amount);
        stakes[stake_for] += _amount;
    }

    function auto_stake(uint _amount, address _stake_for) public onlyFull {
        //dao_token.transferFrom(address(pool_contract), address(this), _amount);
        stakes[_stake_for] += _amount;
    }

    function get_stake(address _user) public view onlyFull returns (uint){
        return stakes[_user];
    }

    function claim(uint _amount, address _user) public {  // 50
        uint user_stake = stakes[msg.sender];  // 2
        if (user_stake < _amount) {  // 2*50 < 50
            dao_token.transfer(msg.sender, user_stake);
        } else {
            dao_token.transfer(msg.sender, _amount);
            }
    }

    function addErc20Asset(address _asset_address) public onlyFull {  // Check struct Asset for details
        //require(vault.asset_locked[_asset_address][_asset_id] == false, "This asset is already locked");
        vault.erc20.push(Asset(_asset_address));

        vault.asset_locked[_asset_address] = true;
    }

    function getErc20Assets() public view onlyFull returns(Asset[] memory) {
        /*
        Get locked assets. UI should iterate over them checking the owner is this DAO
        */
        return vault.erc20;
    }

    // Will be refactored
    function distributeDaoTokens() public onlyFull {
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
}