pragma solidity ^0.5.0;

import "./interfaces/HydroInterface.sol";
import "./interfaces/SnowflakeInterface.sol";
import "./interfaces/IdentityRegistryInterface.sol";

import "./zeppelin/ownership/Ownable.sol";
import "./zeppelin/math/SafeMath.sol";

// @deprecated
/*
contract HydroRinkeby {
    function getMoreTokens() external;
}
*/

contract DemoHelper is Ownable {
    using SafeMath for uint;
    
    address public snowflakeAddress;
    SnowflakeInterface private snowflake;
    IdentityRegistryInterface private identityRegistry;
    address public snowMoResolverAddress;
    
    uint constant atomicUnit = 10**18;
    
    address public hydroTokenAddress;
    bool public airdropActive;
    
    uint private _regUsers;
    bool private _blockRewards; 
    
    uint public milestoneStartRange;
    
    uint public milestoneUno;
    uint public rewardUno;
    
    uint public milestoneDuo;
    uint public rewardDuo;
    
    uint public milestoneTrio;
    uint public rewardTrio;
    
    constructor (address _snowflakeAddress, address _resolverAddress, address _hydroTokenAddress) public {
        snowflakeAddress = _snowflakeAddress;
        snowflake = SnowflakeInterface(snowflakeAddress);
        identityRegistry = IdentityRegistryInterface(snowflake.identityRegistryAddress());
        snowMoResolverAddress = _resolverAddress;
        
        hydroTokenAddress = _hydroTokenAddress;
        
        // Primary Rewards
        milestoneUno = 2000;
        rewardUno = 10000 * atomicUnit;
        
        milestoneDuo = 5000;
        rewardDuo = 5000 * atomicUnit;
        
        milestoneTrio = 10000;
        rewardTrio = 1000 * atomicUnit;
        
        airdropActive = true;
    }

    // wrap createIdentityDelegated and initialize the client raindrop resolver
    function createIdentityDelegated(
        address associatedAddress, address tokensReceivedAddress,
        uint8 v, bytes32 r, bytes32 s, uint timestamp
    ) public returns (uint ein) {
        // create 1484 identity
        address[] memory _providers = new address[](2);
        _providers[0] = snowflakeAddress;
        _providers[1] = address(this);

        uint _ein = identityRegistry.createIdentityDelegated(
            associatedAddress, associatedAddress, _providers, new address[](0), v, r, s, timestamp
        );

        // add snowmo resolver
        snowflake.addResolverAsProvider(
            _ein, snowMoResolverAddress, true, 0, abi.encode(associatedAddress, tokensReceivedAddress)
        );

        // @deprecated
        // get free testnet tokens
        // HydroRinkeby(snowflake.hydroTokenAddress()).getMoreTokens();

        // deposit new tokens into snowflake
        // HydroInterface(snowflake.hydroTokenAddress())
        //     .approveAndCall(snowflakeAddress, 10000000000000000000000, abi.encode(_ein));
        
        // Increment users and Apply Reward Logic
        _regUsers.add(1);
        
        // Calculate reward
        uint rewards;
        if (_regUsers > milestoneStartRange && _regUsers <= milestoneUno + milestoneStartRange) {
            rewards = rewardUno;
        }
        else if (_regUsers > milestoneStartRange && _regUsers <= milestoneDuo + milestoneStartRange) {
            rewards = rewardDuo;
        }
        else if (_regUsers > milestoneStartRange && _regUsers <= milestoneTrio + milestoneStartRange) {
            rewards = rewardTrio;
        }
        
        // Give reward to snowflake id if reward greater than 0 and rewards are not blocked 
        if (rewards > 0 && _blockRewards == false) {
            HydroInterface(snowflake.hydroTokenAddress())
                .approveAndCall(snowflakeAddress, rewards, abi.encode(_ein));
                
            airdropActive = true;
        }
        else {
            airdropActive = false;
        }
        
        return _ein;
    }
    
    function blockRewards(bool value) public onlyOwner {
        _blockRewards = value;
    }
    
    function getRegisteredUsers() public view returns (uint registeredUsers) {
        registeredUsers = _regUsers;
    }
    
    function sethydroTokenAddress(address _newhydroTokenAddress) public onlyOwner {
        hydroTokenAddress = _newhydroTokenAddress;
    }
    
    function setMilestoneStartRange(uint _startRange) public onlyOwner {
        milestoneStartRange = _startRange;
    }
    
    function setMilestones (
        uint _milestoneUno,
        uint _rewardUno,
        uint _milestoneDuo,
        uint _rewardDuo,
        uint _milestoneTrio,
        uint _rewardTrio
    )
    public onlyOwner {
        require(_milestoneUno > 0);
        require(_milestoneDuo > _milestoneUno);
        require(_milestoneTrio > _milestoneDuo);
        
        require(_rewardUno > 0);
        require(_rewardDuo > 0);
        require(_rewardTrio > 0);
        
        milestoneUno = _milestoneUno;
        rewardUno = _rewardUno;
        
        milestoneDuo = _milestoneDuo;
        rewardDuo = _rewardDuo;
        
        milestoneTrio = _milestoneTrio;
        rewardTrio = _rewardTrio;
    }
    
    function withdraw(uint amount) public onlyOwner returns(bool) {
        require(amount <= address(this).balance);
        msg.sender.transfer(amount);
        
        return true;
    }
    
    function withdrawToken(uint amount) public onlyOwner returns (bool) {
        HydroInterface hydro = HydroInterface(hydroTokenAddress);
        hydro.transfer(msg.sender, amount);
        
        return true;
    }
    
    function() external payable { }
}
