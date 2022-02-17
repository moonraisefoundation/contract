// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MoonRaisePrivateSale is Ownable {
    using SafeMath for uint256;

    mapping(address => bool) public _whiteLists;
    mapping(address => uint256) public _balances;
    uint256 public _minUserCap = 1250 ether; // 100$ = 1250 MRT
    uint256 public _maxUserCap = 6250 ether; // 500$ = 6250 MRT
    uint256 public _totalAllocation = 5_000_000 ether; // 5% total supply
    uint256 public _currentAllocation = 0 ether;
    IERC20 public _moonRaiseToken;
    IERC20 public _paymentToken;
    IERC20 public _assetToken;
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

    function setUserCap(uint256 minUserCap, uint256 maxUserCap)
        public
        onlyOwner
    {
        _minUserCap = minUserCap;
        _maxUserCap = maxUserCap;
    }

    function setWhiteLists(address[] memory whiteLists) public onlyOwner {
        for (uint256 i = 0; i < whiteLists.length; i++) {
            _whiteLists[whiteLists[i]] = true;
        }
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

    function isInWhiteList(address account) public view returns (bool) {
        return _whiteLists[account];
    }

    function withdrawFund(uint256 amount) public onlyOwner {
        _paymentToken.transfer(msg.sender, amount);
    }

    function withdrawAsset(IERC20 assetToken, uint256 amount) public onlyOwner {
        assetToken.transfer(msg.sender, amount);
    }

    function buy(uint256 amountInUsd) public onOpenTime {
        require(isInWhiteList(msg.sender), "sender is not in whitelist");
        require(
            _currentAllocation <= _totalAllocation,
            "total allocation is sold out"
        );
        uint256 amountMRT = (amountInUsd * 100) / 8;
        require(
            _balances[msg.sender] + amountMRT <= _maxUserCap,
            "Maximum purchase limit exceeded"
        );
        if (_balances[_msgSender()] == 0) {
            require(
                amountMRT >= _minUserCap,
                "Minimum purchase limit has not been reached"
            );
        }
        _paymentToken.transferFrom(msg.sender, address(this), amountInUsd);
        _balances[msg.sender] = _balances[msg.sender].add(amountMRT);
        _currentAllocation = _currentAllocation.add(amountMRT);
    }

    function claim() public onReleaseTime {
        require(isInWhiteList(msg.sender), "sender is not in whitelist");
        _moonRaiseToken.transfer(msg.sender, _balances[msg.sender]);
        _balances[msg.sender] = 0;
    }
}
