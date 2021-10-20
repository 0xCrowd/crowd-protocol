// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Pool.sol"
import "./DAOToken.sol"
import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/IERC721Upgradeable.sol";


contract DAO is Initializable {
    /* 
    There are 3 stages of pool:
    */ 
    // cбор, сбор закончен, сбор отменен
    enum poolStages{IN_PROGRESS, FULL, FAILED}

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
    tages public stage = Stages.IN_PROGRESS;
    Pool pool;
    uint goal;
    ERC20 dao_token;

    modifier poolStages(Stages _stage) {
        require(stage == _stage);
        _;}

    modifier transitionAfter() {
        _;
        nextStage();
    }

    function initialize (IERC721Upgradeable _nftAddress,
                uint _nftId, 
                uint _payment, // to create DAO you need to send the first payment
                uint _goal,
                address _creator,
                string memory _name, 
                string memory _ticker,
                uint _daoId) internal initializer {
        
        pool.initialize(_goal, _payment, _goal)
        //
        dao_token = new DAOToken(_name, _ticker, _shares_amount, address(pool));
        name = _name;
        

    function recieve_money(address _user) public payable {

    }

    function add_asset(address _asset_address, uint _asset_id) public {  // Check struct Asset for details
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

    function get_asset(uint _asset_type) public view returns(Asset[] memory) {
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
}