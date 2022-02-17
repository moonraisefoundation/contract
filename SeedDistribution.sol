// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract SeedDistribution is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    IERC20 public moonRaiseToken;

    struct Seeder {
        uint256 buyAmount;
        uint256 hadWithdraw;
    }

    mapping(address => Seeder) private seeders;
    uint256 public MONTHS_FOR_RELEASE_DONE = 20;
    uint256 public DAYS_PER_MONTH = 30;
    uint256 public TIMESTAMP_PER_MONTH = DAYS_PER_MONTH.mul(86400);
    uint256 public openingReleaseTime;
    bool public emergencyStatus = false;

    event Claim(address seeder, uint256 amount);
    event ClaimEmergency(address seeder, uint256 amount);

    constructor(IERC20 token) public {
        moonRaiseToken = token;
    }

    modifier onlyInReleaseTime() {
        require(openingReleaseTime <= block.timestamp, "not in releasing time");
        _;
    }

    function setMoonRaiseToken(IERC20 token) public onlyOwner {
        moonRaiseToken = token;
    }

    function setEmergencyStatus(bool status) public onlyOwner {
        emergencyStatus = status;
    }

    modifier onlyEmergency() {
        require(emergencyStatus == true, "onlyEmergency");
        _;
    }

    function setReleaseTime(uint256 time) public onlyOwner {
        openingReleaseTime = time;
    }

    function setTokenForSeeder(address addr, uint256 amount)
        public
        onlyOwner
    {
        require(amount >= 0, "invalid amount");
        seeders[addr].buyAmount = amount;
        seeders[addr].hadWithdraw = 0;
    }

    function getSeederInfo(address addr)
        public
        view
        returns (Seeder memory)
    {
        return seeders[addr];
    }

    function monthFromReleaseToNow()
        public
        view
        onlyInReleaseTime
        returns (uint256)
    {
        uint256 time = block.timestamp.sub(openingReleaseTime);
        uint256 months = time.div(TIMESTAMP_PER_MONTH);
        return months;
    }

    function amountMRTReleasedToNow(uint256 months)
        internal
        returns (uint256)
    {
        uint256 amount = 0;
        if (months <= MONTHS_FOR_RELEASE_DONE) {
            amount = seeders[msg.sender].buyAmount.mul(months).div(
                MONTHS_FOR_RELEASE_DONE
            );
        } else {
            amount = seeders[msg.sender].buyAmount;
        }
        return amount;
    }

    function getBalancers() internal returns (uint256) {
        uint256 months = monthFromReleaseToNow();
        uint256 totalAmountRelease = amountMRTReleasedToNow(months);
        uint256 balancer = totalAmountRelease.sub(
            seeders[msg.sender].hadWithdraw
        );
        return balancer;
    }

    function claim() public onlyInReleaseTime {
        uint256 amount = getBalancers();
        moonRaiseToken.safeTransfer(msg.sender, amount);
        seeders[msg.sender].hadWithdraw = seeders[msg.sender].hadWithdraw.add(
            amount
        );
        emit Claim(msg.sender, amount);
    }

    function claimEmergency() public onlyEmergency {
        uint256 amountClaim = seeders[msg.sender].buyAmount.sub(
            seeders[msg.sender].hadWithdraw
        );
        moonRaiseToken.safeTransfer(msg.sender, amountClaim);
        seeders[msg.sender].hadWithdraw = seeders[msg.sender].hadWithdraw.add(
            amountClaim
        );
        emit ClaimEmergency(msg.sender, amountClaim);
    }

    function withdrawAsset(IERC20 assetToken, uint256 amount) public onlyOwner {
        assetToken.safeTransfer(msg.sender, amount);
    }
}
