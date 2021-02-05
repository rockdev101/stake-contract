// SPDX-License-Identifier: agpl-3.0
pragma solidity ^0.6.0;

import { SafeMath } from '@openzeppelin/contracts/math/SafeMath.sol';

import { StakeDelegationStorages } from "./stake-delegation/commons/StakeDelegationStorages.sol";
import { StakeDelegationEvents } from "./stake-delegation/commons/StakeDelegationEvents.sol";
import { StakeDelegationConstants } from "./stake-delegation/commons/StakeDelegationConstants.sol";

import { OneInch } from "./1inch/1inch-token/OneInch.sol";
import { GovernanceMothership } from "./1inch/1inch-token-staked/st-1inch/GovernanceMothership.sol";
import { MooniswapFactoryGovernance } from "./1inch/1inch-governance/governance/MooniswapFactoryGovernance.sol";
import { GovernanceRewards } from "./1inch/1inch-governance/governance/GovernanceRewards.sol";


/**
 * @notice - A liquidity protocol stake delegation contract.
 * @notice - A contract is able to vote on specific parameters in https://1inch.exchange/#/dao/governance for stake and vote delegation and automatic 1inch reward distribution to stakers.
 */
contract StakeDelegation is StakeDelegationStorages, StakeDelegationEvents, StakeDelegationConstants {
    using SafeMath for uint256;

    address[] delegators;  /// All delegators addresses

    OneInch public oneInch;                 /// 1INCH Token
    GovernanceMothership public stOneInch;  /// st1INCH token
    MooniswapFactoryGovernance public mooniswapFactoryGovernance;  /// For voting
    GovernanceRewards public governanceRewards;                    /// For claiming rewards

    address ST_ONEINCH;

    constructor(OneInch _oneInch, GovernanceMothership _stOneInch, MooniswapFactoryGovernance _mooniswapFactoryGovernance, GovernanceRewards _governanceRewards) public {
        oneInch = _oneInch;
        stOneInch = _stOneInch;
        mooniswapFactoryGovernance = _mooniswapFactoryGovernance;
        governanceRewards = _governanceRewards;

        ST_ONEINCH = address(stOneInch);
    }


    ///-------------------------------------------------------
    /// Registor a delegator address and information
    ///-------------------------------------------------------
    function registerDelegator(address delegator, uint delegatedAmount, uint blockNumber) public returns (bool) {
        delegators.push(delegator);
        _saveDelegatorInfo(delegator, delegatedAmount, blockNumber);
    }

    function _saveDelegatorInfo(address delegator, uint delegatedAmount, uint blockNumber) internal returns(bool) {
        DelegatorInfo storage delegatorInfo = delegatorInfos[delegator];
        delegatorInfo.delegatedAmount;
        delegatorInfo.blockNumber;
    }


    ///-------------------------------------------------------
    /// Delegate staking
    ///-------------------------------------------------------
    function delegateStaking(uint stakeAmount) public returns (bool) {
        oneInch.approve(ST_ONEINCH, stakeAmount);
        stOneInch.stake(stakeAmount);
    }


    ///-------------------------------------------------------
    /// Delegate voting
    ///-------------------------------------------------------    
    function delegateFeeVote(uint vote) public returns (bool) {
        mooniswapFactoryGovernance.defaultFeeVote(vote);
    }

    function delegateSlippageFeeVote(uint vote) public returns (bool) {
        mooniswapFactoryGovernance.defaultSlippageFeeVote(vote);
    }

    function delegateDecayPeriodVote(uint vote) public returns (bool) {
        mooniswapFactoryGovernance.defaultDecayPeriodVote(vote);
    }

    function delegateReferralShareVote(uint vote) public returns (bool) {
        mooniswapFactoryGovernance.referralShareVote(vote);
    }

    function delegateGovernanceShareVote(uint vote) public returns (bool) {
        mooniswapFactoryGovernance.governanceShareVote(vote);
    }


    ///-----------------------------------------------------------------
    /// Delegate reward distribution (Claim or UnStake)
    ///-----------------------------------------------------------------
    /**
     * @notice - Delegate reward distribution with claim (fill amount)
     */
    function delegateRewardDistributionWithClaim() public returns (bool) {
        uint rewardAmount = governanceRewards.earned(address(this)); 
        governanceRewards.getReward();
        oneInch.transfer(msg.sender, rewardAmount);

        /// [Todo]: Distribute rewards into each users depends on "share" of delegated amount
    }

    /**
     * @notice - Delegate reward distribution with Un-Stake (specified-amount)
     */
    function delegateRewardDistributionWithUnStake(uint unStakeAmount) public returns (bool) {
        stOneInch.unstake(unStakeAmount);
        oneInch.transfer(msg.sender, unStakeAmount);

        /// [Todo]: Distribute rewards into each users depends on "share" of delegated amount
    }


    ///------------------------------------------------------------
    /// Getter methods
    ///------------------------------------------------------------
    /**
     * @notice - Get all delegators addresses of this StakeDelegation contract
     */
    function getDelegatedAddresses() public view returns (address[] memory _delegators) {
        return delegators;
    }
    
}

