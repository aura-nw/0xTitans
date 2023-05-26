// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "./../../interfaces/ICar.sol";

contract PhongCar is ICar {
    function updateBalance(
        Monaco.CarData memory ourCar,
        uint cost
    ) internal pure {
        ourCar.balance -= uint24(cost);
    }

    function buyAsMuchAccelerationAsSensible(
        Monaco monaco,
        Monaco.CarData memory ourCar
    ) internal {
        uint256 baseCost = 25;
        uint256 speedBoost = ourCar.speed < 5 ? 5 : ourCar.speed < 10
            ? 3
            : ourCar.speed < 15
            ? 2
            : 1;
        uint256 yBoost = ourCar.y < 100 ? 1 : ourCar.y < 250
            ? 2
            : ourCar.y < 500
            ? 3
            : ourCar.y < 750
            ? 4
            : ourCar.y < 950
            ? 5
            : 10;
        uint256 costCurve = baseCost * speedBoost * yBoost;
        // uint costCurve = 25 * ((5 / (ourCar.speed + 1))+1) * ((ourCar.y + 1000) / 500);
        uint256 speedCurve = 8 * ((ourCar.y + 500) / 300);

        while (
            hasEnoughBalance(ourCar, monaco.getAccelerateCost(1)) &&
            monaco.getAccelerateCost(1) < costCurve &&
            ourCar.speed < speedCurve
        ) updateBalance(ourCar, monaco.buyAcceleration(1));
    }

    function hasEnoughBalance(
        Monaco.CarData memory ourCar,
        uint cost
    ) internal pure returns (bool) {
        return ourCar.balance > cost;
    }

    function buyAsMuchAccelerationAsPossible(
        Monaco monaco,
        Monaco.CarData memory ourCar
    ) internal {
        while (hasEnoughBalance(ourCar, monaco.getAccelerateCost(1)))
            updateBalance(ourCar, monaco.buyAcceleration(1));
    }

    function buy1ShellWhateverThePrice(
        Monaco monaco,
        Monaco.CarData memory ourCar
    ) internal {
        if (hasEnoughBalance(ourCar, monaco.getShellCost(1)))
            updateBalance(ourCar, monaco.buyShell(1));
    }

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata /*bananas*/,
        uint256 ourCarIndex
    ) external {
        Monaco.CarData memory ourCar = allCars[ourCarIndex];
        Monaco.CarData memory otherCar1 = allCars[ourCarIndex == 0 ? 1 : 0];
        Monaco.CarData memory otherCar2 = allCars[ourCarIndex == 2 ? 1 : 2];
        bool isCar1Ahead = otherCar1.y > ourCar.y;
        bool isCar2Ahead = otherCar2.y > ourCar.y;
        bool hasCarAhead = isCar1Ahead || isCar2Ahead;
        if (monaco.turns() == 10) {
            // monaco.buyShell();
            // monaco.buyShield(2);
            // buyAsMuchAccelerationAsSensible(monaco, ourCar);
            monaco.buyAcceleration(10);
        }
        if (monaco.turns() == 12) {
            monaco.buyAcceleration(10);
        }
        if (monaco.turns() == 15) {
            monaco.buyAcceleration(10);
        }
        if (monaco.turns() == 17) {
            monaco.buyAcceleration(10);
        }
        if (monaco.turns() == 20) {
            monaco.buyAcceleration(10);
        }
        if (monaco.turns() == 25) {
            monaco.buyAcceleration(10);
        }
        if (monaco.turns() == 27) {
            monaco.buyAcceleration(10);
        }
        if (monaco.turns() > 32) {
            monaco.buyShield(2);
            monaco.buyShell(2);
            buyAsMuchAccelerationAsPossible(monaco, ourCar);
        }
        // if (hasCarAhead) {
        //     buy1ShellWhateverThePrice(monaco, ourCar);
        // }
    }

    function sayMyName() external pure returns (string memory) {
        return "PhongCar";
    }
}
