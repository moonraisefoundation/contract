// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonRaisePreSaleSeriesB is Ownable {
    using SafeMath for uint256;

    mapping(address => uint256) public _balances;
    uint256 public _totalAllocation = 2_500_000 ether; // 2.5% total supply
    uint256 public _currentAllocation = 0 ether;
    IERC20 public _moonRaiseToken;
    IERC20 public _paymentToken;
    uint256 public _openTime;
    uint256 public _closeTime;
    uint256 public _unlockTime;

    constructor(
        IERC20 moonRaiseToken,
        IERC20 paymentToken,
        uint256 openTime,
        uint256 closeTime,
        uint256 unlockTime
    ) public {
        _moonRaiseToken = moonRaiseToken;
        _paymentToken = paymentToken;
        _openTime = openTime;
        _closeTime = closeTime;
        _unlockTime = unlockTime;
    }

    function setOpenTime(uint256 openTime) public onlyOwner {
        _openTime = openTime;
    }

    function setCloseTime(uint256 closeTime) public onlyOwner {
        _closeTime = closeTime;
    }

    function setUnLockTime(uint256 unlockTime) public onlyOwner {
        _unlockTime = unlockTime;
    }

    function setMoonRaiseToken(IERC20 moonRaiseToken) public onlyOwner {
        _moonRaiseToken = moonRaiseToken;
    }

    function setPaymentToken(IERC20 paymentToken) public onlyOwner {
        _paymentToken = paymentToken;
    }

    modifier onOpenTime() {
        require(
            (_openTime <= block.timestamp && block.timestamp <= _closeTime),
            "It's is not during open time"
        );
        _;
    }

    modifier onReleaseTime() {
        require(block.timestamp >= _unlockTime, "It's not time to unlock yet");
        _;
    }

    function withdrawFund(uint256 amount) public onlyOwner {
        _paymentToken.transfer(msg.sender, amount);
    }

    function withdrawAsset(IERC20 assetToken, uint256 amount) public onlyOwner {
        assetToken.transfer(msg.sender, amount);
    }

    function buy(uint256 amountInUsd) public onOpenTime {
        require(
            _currentAllocation <= _totalAllocation,
            "total allocation is sold out"
        );
        uint256 amountMRT = (amountInUsd * 100) / 14;
        _paymentToken.transferFrom(msg.sender, address(this), amountInUsd);
        _balances[msg.sender] = _balances[msg.sender].add(amountMRT);
        _currentAllocation = _currentAllocation.add(amountMRT);
    }

    function claim() public onReleaseTime {
        _moonRaiseToken.transfer(msg.sender, _balances[msg.sender]);
        _balances[msg.sender] = 0;
    }
}
