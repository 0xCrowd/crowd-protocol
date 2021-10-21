// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./v1Pool.sol";
import "./DAOToken.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";


contract DAO is Initializable, IERC721Receiver {
    /* 
    There are 3 stages of pool:
    */ 
    // cбор, сбор закончен, сбор отменен
    enum poolStages{ IN_PROGRESS, FULL }

    struct Asset {
        address addr;  // Address of stored asset
        uint id;  // Should be zero for ERC20 and non-zero for ERC721
    }

    struct Vault {
        mapping(address => mapping(uint => bool)) asset_locked;
        Asset[] erc721;  // Locked NFTs
        Asset[] erc20;  // Locked ERC20
    }

    Vault vault;
    poolStages public stage = poolStages.IN_PROGRESS;
    Pool pool;
    uint goal;
    ERC20 dao_token;

    modifier onlyFull() { require(stage ==  Stages.FULL); _; }
    modifier transitionAfter() { _; nextStage(); }

    function initialize (IERC721Upgradeable _nftAddress,
                uint _nftId, 
                uint _payment, // to create DAO you need to send the first payment
                // uint _goal,  // ToDo remove: Goal might be changed and will be got from the off-chain oracle.
                // address _creator,  // ToDo no usage: Do we need creator?
                string memory _name, 
                string memory _ticker,
                uint _daoId) internal initializer {
        
        pool.initialize(_goal, _payment, _goal);
        dao_token = new DAOToken(
                _name,
                _ticker,
                _shares_amount,  // ToDo initialize: We should discuss the amount of minted shares.
                address(pool));
        name = _name;
    }

    function getDeposit(address _user) public payable {}

    function stake(uint _amount, address stake_for) public onlyFull {
        if (dao_token.allowance(stake_for, address(this)) < _amount) {
            dao_token.approve(address(this), _amount);
        }
        dao_token.transferFrom(msg.sender, address(this), _amount);
        stakes[stake_for] += _amount;
    }

    function auto_stake(uint _amount, address _stake_for) public onlyFull {
        dao_token.transferFrom(address(pool_contract), address(this), _amount);
        stakes[_stake_for] += _amount;
    }

    function get_stake(address _user) public view onlyFull returns (uint){
        return stakes[_user];
    }

    function claim(uint _amount) public {  // 50
        uint user_stake = stakes[msg.sender];  // 2
        if (user_stake < _amount) {  // 2*50 < 50
            dao_token.transfer(msg.sender, user_stake);
        } else {
            dao_token.transfer(msg.sender, _amount);
            }
    }

    function addAsset(address _asset_address, uint _asset_id) public onlyFull {  // Check struct Asset for details
        require(vault.asset_locked[_asset_address][_asset_id] == false, "This asset is already locked");
        if (_asset_id != 0) {  // NFT
            IERC721 asset = IERC721(_asset_address);
            require(asset.ownerOf(_asset_id) == address(this), "This asset isn't locked");
            vault.erc721.push(Asset(_asset_address, _asset_id));
        } else {  // ERC20
            vault.erc20.push(Asset(_asset_address, _asset_id));
        }
        vault.asset_locked[_asset_address][_asset_id] = true;
    }

    function getAsset(uint _asset_type) public view onlyFull returns(Asset[] memory) {
        /*
        Get locked assets. UI should iterate over them checking the owner is this DAO
        _asset_type: 0 - "erc721" / 1 - "erc20"
        */
        if (_asset_type == 0) {
            return vault.erc721;
        } else {
            if (_asset_type == 1) {
                return vault.erc20;
            }
        }
        Asset[] memory empty;
        return empty;
    }
}