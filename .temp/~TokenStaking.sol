// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "d:/Fuzen/fuzen-smart-contract/node_modules/@openzeppelin/contracts/access/Ownable.sol";
import "./lib/~SafeMath.sol";

contract TokenStaking is Ownable {
    using SafeMath for uint256;

    /**
     *  @dev Structs to store user staking data.
     */
    struct Deposits {
        uint256 depositAmount;
        uint256 depositTime;
        uint256 endTime;
        uint64 userIndex;
        uint256 rewards;
        bool paid;
    }

    /**
     *  @dev Structs to store interest rate change.
     */
    struct Rates {
        uint64 newInterestRate;
        uint256 timeStamp;
    }

    mapping(address => Deposits) private deposits;
    mapping(uint64 => Rates) public rates;
    mapping(address => bool) private hasStaked;

    uint256 public stakedBalance;
    uint256 public stakedTotal;
    uint64 public index;
    uint64 public rate;
    uint256 public lockDuration;
    string public name;
    uint256 public totalParticipants;
    bool public isStopped;

    /**
     *  @dev Emitted when user stakes 'stakedAmount' value of tokens
     */
    event Staked(
        address indexed staker_,
        uint256 stakedAmount_
    );

    /**
     *  @dev Emitted when user withdraws his stakings
     */
    event PaidOut(
        address indexed staker_,
        uint256 amount_,
        uint256 reward_
    );

    event RateAndLockduration(
        uint64 index,
        uint64 newRate,
        uint256 lockDuration,
        uint256 time
    );

    event StakingStopped(bool status, uint256 time);

    /**
     *   @param
     *   name_ name of the contract
     *   tokenAddress_ contract address of the token
     *   rate_ rate multiplied by 100
     *   lockduration_ duration in days
     */
    constructor(
        address _initialOwner,
        string memory name_,
        uint64 rate_,
        uint256 lockDuration_
    ) public Ownable(_initialOwner) {
        name = name_;
        lockDuration = lockDuration_;
        require(rate_ != 0, "Zero interest rate");
        rate = rate_;
        rates[index] = Rates(rate, block.timestamp);
    }

    /**
     *  Requirements:
     *  `rate_` New effective interest rate multiplied by 100
     *  @dev to set interest rates
     *  `lockduration_' lock days
     *  @dev to set lock duration days
     */
    function setRateAndLockduration(uint64 rate_, uint256 lockduration_)
        external
        onlyOwner
    {
        require(rate_ != 0, "Zero interest rate");
        require(lockduration_ != 0, "Zero lock duration");
        rate = rate_;
        index++;
        rates[index] = Rates(rate_, block.timestamp);
        lockDuration = lockduration_;
        emit RateAndLockduration(index, rate_, lockduration_, block.timestamp);
    }

    function changeStakingStatus(bool _status) external onlyOwner {
        isStopped = _status;
        emit StakingStopped(_status, block.timestamp);
    }

    /**
     *  Requirements:
     *  `user` User wallet address
     *  @dev returns user staking data
     */
    function userDeposits(address user)
        external
        view
        returns (
            uint256 depositAmount,
            uint256 depositTime,
            uint256 endTime,
            uint256 userIndex,
            uint256 rewards,
            bool paid
        )
    {
        if (hasStaked[user]) {
            return (
                deposits[user].depositAmount,
                deposits[user].depositTime,
                deposits[user].endTime,
                deposits[user].userIndex,
                deposits[user].rewards,
                deposits[user].paid
            );
        }
    }

    /**
     *  Requirements:
     *  `amount` Amount to be staked
     /**
     *  @dev to stake 'amount' value of tokens 
     *  once the user has given allowance to the staking contract
     */

    function stake()
        external
        payable
        _realAddress(msg.sender)
        returns (bool)
    {
        require(msg.value > 0, "Can't stake 0 amount");
        require(!isStopped, "Staking paused");
        return (_stake(msg.sender, msg.value));
    }

    function _stake(address from, uint256 amount) private returns (bool) {
        if (!hasStaked[from]) {
            hasStaked[from] = true;

            deposits[from] = Deposits(
                amount,
                block.timestamp,
                block.timestamp.add((lockDuration.mul(3600))),
                index,
                0,
                false
            );
            totalParticipants = totalParticipants.add(1);
        } else {
            require(
                block.timestamp < deposits[from].endTime,
                "Lock expired, please withdraw and stake again"
            );
            uint256 newAmount = deposits[from].depositAmount.add(amount);
            uint256 rewards = _calculate(from, block.timestamp).add(
                deposits[from].rewards
            );
            deposits[from] = Deposits(
                newAmount,
                block.timestamp,
                block.timestamp.add((lockDuration.mul(3600))),
                index,
                rewards,
                false
            );
        }
        stakedBalance = stakedBalance.add(amount);
        stakedTotal = stakedTotal.add(amount);
        emit Staked(from, amount);

        return true;
    }

    /**
     * @dev to withdraw user stakings after the lock period ends.
     */
    function withdraw() external _realAddress(msg.sender) returns (bool) {
        require(hasStaked[msg.sender], "No stakes found for user");
        require(
            block.timestamp >= deposits[msg.sender].endTime,
            "Requesting before lock time"
        );
        require(!deposits[msg.sender].paid, "Already paid out");
        return (_withdraw(msg.sender));
    }

    function _withdraw(address from) private returns (bool) {
        uint256 reward = _calculate(from, deposits[from].endTime);
        reward = reward.add(deposits[from].rewards);
        uint256 amount = deposits[from].depositAmount;
        stakedBalance = stakedBalance.sub(amount);
        deposits[from].paid = true;
        deposits[from].rewards = reward;
        hasStaked[from] = false;
        totalParticipants = totalParticipants.sub(1);
        payable(from).transfer(amount);
        emit PaidOut(from, amount, reward);
        return false;
    }

    function emergencyWithdraw()
        external
        _realAddress(msg.sender)
        returns (bool)
    {
        require(hasStaked[msg.sender], "No stakes found for user");
        require(!deposits[msg.sender].paid, "Already paid out");

        return (_emergencyWithdraw(msg.sender));
    }

    function _emergencyWithdraw(address from) private returns (bool) {
        uint256 amount = deposits[from].depositAmount;
        stakedBalance = stakedBalance.sub(amount);
        deposits[from].paid = true;
        hasStaked[from] = false; //Check-Effects-Interactions pattern
        totalParticipants = totalParticipants.sub(1);

        payable(from).transfer(amount);
        emit PaidOut(from, amount, 0);

        return true;
    }

    /**
     *  Requirements:
     *  `from` User wallet address
     * @dev to calculate the rewards based on user staked 'amount'
     * 'userIndex' - the index of the interest rate at the time of user stake.
     * 'depositTime' - time of staking
     */
    function calculate(address from, uint256 _timestamp) external view returns (uint256) {
        return _calculate(from, _timestamp);
    }

    function _calculate(address from, uint256 endTime)
        private
        view
        returns (uint256)
    {
        if (!hasStaked[from]) return 0;
        (uint256 amount, uint256 depositTime, uint64 userIndex) = (
            deposits[from].depositAmount,
            deposits[from].depositTime,
            deposits[from].userIndex
        );

        uint256 time;
        uint256 interest;
        uint256 _lockduration = deposits[from].endTime.sub(depositTime);
        for (uint64 i = userIndex; i < index; i++) {
            //loop runs till the latest index/interest rate change
            if (endTime < rates[i + 1].timeStamp) {
                //if the change occurs after the endTime loop breaks
                break;
            } else {
                time = rates[i + 1].timeStamp.sub(depositTime);
                interest = amount.mul(rates[i].newInterestRate).mul(time).div(
                    _lockduration.mul(10000)
                );
                amount = amount.add(interest);
                depositTime = rates[i + 1].timeStamp;
                userIndex++;
            }
        }

        if (depositTime < endTime) {
            //final calculation for the remaining time period
            time = endTime.sub(depositTime);

            interest = time
                .mul(amount)
                .mul(rates[userIndex].newInterestRate)
                .div(_lockduration.mul(10000));
        }

        return (interest);
    }

    modifier _realAddress(address addr) {
        require(addr != address(0), "Zero address");
        _;
    }
}