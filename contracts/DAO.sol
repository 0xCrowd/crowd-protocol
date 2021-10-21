// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./DAOToken.sol";
import "./CRUD.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract DAO is Initializable, Ownable {
    /* 
    Right now there are 2 stages of funding process:
    */ 
    // cбор, сбор закончен, сбор отменен
    enum Stages{ IN_PROGRESS, FULL }

    struct Vault {
        mapping(address => bool) assetLocked;
        address[] erc20;  // Locked ERC20
    }

    CRUD users = new CRUD();
    mapping(address => uint) userToEth;
    Vault public vault;
    address owner;
    Stages public stage = Stages.IN_PROGRESS;
    ERC20 daoToken;
    uint userCount;
    uint total;

    event DistributionDaoToken(IERC721 indexed nft_address, uint nft_id, address sender);

    modifier onlyFull() { require(stage ==  Stages.FULL); _; }

    function nexStage() public onlyOwner{

    }

    function initialize (uint _payment, string memory _name, address _user, string memory _ticker, uint _daoId, uint _shares_amount
                        ) public payable initializer {
        // Get DAO token.
        // Tokens are minted automatically after the contract initialization.
        daoToken = new DAOToken(
                _name,
                _ticker,
                _shares_amount,  // ToDo initialize: We should discuss the amount of minted shares.
                address(this));
        userCount++;
        // Update user stats.
        userToEth[_user] += _payment; 
        // Add the user address to the dynamic array of users.
        users.create(userCount, _user);
        // Get token address.
        address tokenAddress = address(daoToken);
        // Update lock status.
        vault.assetLocked[tokenAddress] = true;
        // Add asset to the list of all assets.
        vault.erc20.push(tokenAddress);
    }

    function recieveDeposit(address _user) public payable {
        userCount++;
        users.create(userCount, _user);
        userToEth[_user] += msg.value; 
    }

    function tokenAddress() public view {
        return address(daoToken);
    }

    function stake(uint _amount, address stake_for, address _user) public onlyFull {
        if (daoToken.allowance(_user, address(this)) < _amount) {
            daoToken.approve(address(this), _amount);
        }
        daoToken.transferFrom(_user, address(this), _amount);
        stakes[stake_for] += _amount;
    }

    function auto_stake(uint _amount, address _stake_for) public onlyFull {
        //daoToken.transferFrom(address(pool_contract), address(this), _amount);
        stakes[_stake_for] += _amount;
    }

    function get_stake(address _user) public view onlyFull returns (uint){
        return stakes[_user];
    }

    function claim(uint _amount, address _user) public {  // 50
        uint userStake = stakes[msg.sender];  // 2
        if (userStake < _amount) {  // 2*50 < 50
            daoToken.transfer(msg.sender, userStake);
        } else {
            daoToken.transfer(msg.sender, _amount);
            }
    }

    function addErc20Asset(address _assetAddress) public onlyFull, onlyOwner {  
        require(vault.assetLocked[_assetAddress]== false, "This asset is already locked");
        vault.erc20.push(Asset(_assetAddress));
        vault.assetLocked[_assetAddress] = true;
    }

    function getErc20Assets() public view onlyFull returns(Asset[] memory) {
        /*
        Get locked assets. UI should iterate over them checking the owner is this DAO
        */
        return vault.erc20;
    }

    // Will be refactored
    function distributeDaoTokens() public onlyFull, onlyOwner {
        uint k = daoToken.totalSupply() / parties[_partyId].totalDeposit;
        Party storage party = parties[_partyId];
        Dao dao = Dao(_dasssoAddress);
        _daoToken.approve(_daoAddress, _daoToken.totalSupply());
        for (uint i = 0; i < parties[_partyId].participants.length; i++) {
            address recipient = party.participants[i];
            dao.auto_stake(shares[_partyId][recipient]*k, recipient);
            userToDaos[recipient].push(_daoAddress);
        }
    }

    function nextStage() internal {
        stage = Stages(uint(stage) + 1);
    }
}