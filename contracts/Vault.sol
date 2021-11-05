// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Token.sol";
import "./CRUD.sol";

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
//import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
//import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "hardhat/console.sol";


contract Vault is Initializable, OwnableUpgradeable, UUPSUpgradeable {
    /* 
    Right now there are 2 stages of funding process:
    */ 
    address public initiator;  // Offchain initiator
    // cбор, сбор закончен, сбор отменен
    enum Stages{ IN_PROGRESS, FULL }

    struct vaultStorage {
        mapping(address => bool) assetLocked;
        address[] erc20;  // Locked ERC20
    }

    address[] users;
    mapping(address => uint) userToEth;
    mapping(address => uint) stakes; 
    vaultStorage vault;
    Stages public stage = Stages.IN_PROGRESS;
    Token vaultToken;
    uint total;

    modifier onlyFull {require(stage ==  Stages.FULL, "The pool is not full yet!"); _;}
    modifier onlyInitiator {require(msg.sender == initiator); _;}

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setInitiator(address _new_initiator) public onlyOwner {
        if (_new_initiator != address(0x0)) {
            initiator = _new_initiator;
        }
    }

    function initialize (string memory _name, string memory _ticker, 
                        uint _shares_amount) public initializer {
        // Tokens are minted automatically after the contract initialization.
        __Ownable_init_unchained();
        vaultToken = new Token();
        vaultToken.initialize(
                _name,
                _ticker,
                _shares_amount,  // ToDo initialize: We should discuss the amount of minted shares.
                address(this));
        // Get token address.
        address tokenAddress = address(vaultToken); 
        //Add asset to the list of all assets.
        addErc20Asset(tokenAddress);
    }

    function recieveDeposit(address _user) public payable {
        if (userToEth[_user] == 0) {
            // Add the user address to the dynamic array of users.
            users.push(_user);
        }
        // Update user stats.
        total += msg.value; 
        userToEth[_user] += msg.value; 
    }

    function getTokenAddress() public view returns(address){
        return address(vaultToken);
    }

    function getTokenName() public view onlyFull returns(string memory) {
        return vaultToken.name();
    }

    function getTokenTicker() public view onlyFull returns(string memory) {
        return vaultToken.symbol();
    }
    
    function getUserDeposit(address _user) public view returns(uint) {
        return userToEth[_user];
    }
    
    function getBalance() public view returns (uint){
        return address(this).balance;
    }

    function stake(uint _amount, 
                  address stake_for, 
                  address _user) public onlyFull {
        if (vaultToken.allowance(_user, address(this)) < _amount) {
            vaultToken.approve(address(this), _amount);
        }
        vaultToken.transferFrom(_user, address(this), _amount);
        stakes[stake_for] += _amount;
    }

    function autoStake(uint _amount, address _user) public onlyFull {
        //vaultToken.transferFrom(address(pool_contract), address(this), _amount);
        stakes[_user] += _amount;
    }

    function getStake(address _user) public view onlyFull returns (uint){
        return stakes[_user];
    }

    function claim(uint _amount, address _user) public onlyFull {  // 50
        uint userStake = stakes[_user];  // 2
        if (userStake < _amount) {  // 2*50 < 50
            vaultToken.transfer(_user, userStake);
        } else {
            vaultToken.transfer(_user, _amount);
            }
    }

    function addErc20Asset(address _assetAddress) public onlyOwner {  
        require(vault.assetLocked[_assetAddress] == false, 
        "This asset is already locked");
        vault.erc20.push(_assetAddress);
        vault.assetLocked[_assetAddress] = true;
    }
    
    function getErc20Assets() public view onlyFull returns(address[] memory) {
        /*
        Get locked assets. UI should iterate over them checking the owner is this vault.
        */
        return vault.erc20;
    }
    
    function distributeTokens() public onlyFull onlyOwner {
        /*
        
        */
        uint k = vaultToken.totalSupply() / total;
        vaultToken.approve(address(this), vaultToken.totalSupply());
        for (uint i = 0; i < users.length; i++) {
            address recipient = users[i];
            autoStake(userToEth[recipient]*k, recipient);
        }
    }

    function goFullStage() public onlyInitiator {
        stage =  Stages.FULL;
    }
}