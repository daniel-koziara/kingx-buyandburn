// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";


contract BuyAndBurnKingX {

    using SafeERC20 for IERC20;

    address private owner;
    IERC20 private titanX;
    IERC20 private kingX;
    ISwapRouter private uniswapRouter;

    uint256 private amountToSwap;
    uint256 private rewardPerCall;
    uint256 private slippage;
    uint256 private minInterval;
    uint256 private lastCallTimestamp;

    bool private paused = true;

    uint256 private totalTitanXBoughtAndBurned;
    uint256 private totalKingXBoughtAndBurned;

    event BuyAndBurn(
        address indexed caller,
        uint256 titanXSpent,
        uint256 kingXReceived
    );

    constructor(address _titanX, address _kingX, address _uniswapRouter) {
        owner = msg.sender;
        titanX = IERC20(_titanX);
        kingX = IERC20(_kingX);
        uniswapRouter = ISwapRouter(_uniswapRouter);
        slippage = 5;
        minInterval = 60;
        amountToSwap = 100000000000000000000000; // 100k titanx
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Caller is not the owner");
        _;
    }

    modifier whenNotPaused() {
        require(!paused, "Contract is paused");
        _;
    }

    function setKingXAddress(address _kingX) external onlyOwner {
        kingX = IERC20(_kingX);
    }

    function setTitanXAddress(address _titanX) external onlyOwner {
        titanX = IERC20(_titanX);
    }

    function pause() external onlyOwner {
        paused = true;
    }

    function unpause() external onlyOwner {
        paused = false;
    }

    function setRewardPerCall(uint256 _reward) external onlyOwner {
        rewardPerCall = _reward;
    }

    function setSlippage(uint256 _slippage) external onlyOwner {
        require(_slippage <= 100, "Slippage too high");
        slippage = _slippage;
    }

    function setAmountToSwap(uint256 _amountToSwap) external onlyOwner {
        amountToSwap = _amountToSwap;
    }

    function setMinInterval(uint256 _interval) external onlyOwner {
        minInterval = _interval;
    }

    function buyAndBurn() external whenNotPaused {
        require(
            block.timestamp - lastCallTimestamp > minInterval,
            "Wait for the next call interval"
        );

        require(msg.sender == tx.origin, "InvalidCaller");


        lastCallTimestamp = block.timestamp;

        titanX.safeTransfer(msg.sender, rewardPerCall);

        uint256 kingXBalanceBefore = kingX.balanceOf(address(this));

        swapTitanXForKingX(amountToSwap);
        uint256 kingXBalanceAfter = kingX.balanceOf(address(this));

        uint256 kingXReceived = kingXBalanceAfter - kingXBalanceBefore;


        totalTitanXBoughtAndBurned += amountToSwap + rewardPerCall;
        totalKingXBoughtAndBurned += kingXReceived;

        emit BuyAndBurn(msg.sender, amountToSwap, kingXReceived);
    }

    function swapTitanXForKingX(uint256 titanXAmount) private whenNotPaused {
        titanX.approve(address(uniswapRouter), titanXAmount);

        ISwapRouter.ExactInputSingleParams memory params = ISwapRouter
            .ExactInputSingleParams({
                tokenIn: address(titanX),
                tokenOut: address(kingX),
                fee: 10000,
                recipient: address(this),
                deadline: block.timestamp + 15 minutes,
                amountIn: titanXAmount,
                amountOutMinimum: 0,
            });

        uniswapRouter.exactInputSingle(params);
    }

    function getRewardPerCall() public view returns (uint256) {
        return rewardPerCall;
    }

    function getSlippage() public view returns (uint256) {
        return slippage;
    }

    function getAmountToSwap() public view returns (uint256) {
        return amountToSwap;
    }

    function getMinInterval() public view returns (uint256) {
        return minInterval;
    }

    function getKingxBalance() public view returns (uint256) {
        return kingX.balanceOf(address(this));
    }

    function getTitanxBalance() public view returns (uint256) {
        return titanX.balanceOf(address(this));
    }

    function getTotalTitanXBoughtAndBurned() public view returns (uint256) {
        return totalTitanXBoughtAndBurned;
    }

    function getTotalKingXBoughtAndBurned() public view returns (uint256) {
        return totalKingXBoughtAndBurned;
    }

    function getIsPausedBnB() public view returns (bool) {
        return paused;
    }
}
