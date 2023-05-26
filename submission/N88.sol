// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

/* Originally published at 

https://gist.github.com/gretzke/f7f3151693113cab9fe7e86b340477a9

Created by the Polygon team 
 */

import "./../interfaces/ICar.sol";

contract N88 is ICar {
    enum Status {
        EARLY_GAME,
        LATE_GAME
    }

    uint256 internal constant BANANA_MAX = 400;
    uint256 internal constant SAFE_DISTANCE = 50;
    // decisions based on stages of the race:
    uint256 ACCEL_MAX = 50;
    uint256 SUPER_SHELL_MAX = 300;
    uint256 SHELL_MAX = 150;
    uint256 SHIELD_MAX = 100;

    uint256 internal constant EARLY_GAME = 200;
    uint256 internal constant MID_GAME = 600;
    uint256 internal constant LATE_GAME = 900;

    Status status = Status.EARLY_GAME;
    uint256 bananasAhead;
    Monaco.CarData[] cars;
    uint256 aheadIndex;
    uint256 aheadCarPosition;
    uint256 remainingBalance;
    uint256 speed = 0;
    uint256 ourCarPosition = 0;
    uint256 ourCarIndex;
    bool bananaBought = false;
    bool superShellBought = false;
    uint256 shields = 0;

    modifier setUp(
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 ourCarIndex
    ) {
        {
            ourCarIndex = ourCarIndex;
            speed = allCars[ourCarIndex].speed;
            shields = allCars[ourCarIndex].shield;
            remainingBalance = allCars[ourCarIndex].balance;
            ourCarPosition = allCars[ourCarIndex].y;
            bananasAhead = 0;
            // setup cars in order
            (uint256 firstIndex, uint256 secondIndex) = (
                (ourCarIndex + 1) % 3,
                (ourCarIndex + 2) % 3
            );
            (
                Monaco.CarData memory firstCar,
                Monaco.CarData memory secondCar
            ) = allCars[firstIndex].y > allCars[secondIndex].y
                    ? (allCars[firstIndex], allCars[secondIndex])
                    : (allCars[secondIndex], allCars[firstIndex]);
            cars.push(secondCar);
            cars.push(firstCar);

            uint256 maxY = allCars[ourCarIndex].y > firstCar.y
                ? allCars[ourCarIndex].y
                : firstCar.y;
            if (maxY > LATE_GAME) {
                ACCEL_MAX = 1000;
                SUPER_SHELL_MAX = 1200;
                SHELL_MAX = 900;
                SHIELD_MAX = 600;
                status = Status.LATE_GAME;
            } else {
                status = Status.EARLY_GAME;
            }

            // get all bananas in our way
            if (ourCarIndex != 0) {
                // we are not in first place
                if (ourCarIndex == 1) {
                    aheadIndex = 1;
                }
                // uint256 ourCarPosition = allCars[ourCarIndex].y;
                uint256 nextCarPosition = ourCarIndex == 1
                    ? firstCar.y
                    : secondCar.y;
                for (uint256 i = 0; i < bananas.length; i++) {
                    if (bananas[i] > ourCarPosition) {
                        ++bananasAhead;
                    }
                    if (bananas[i] > nextCarPosition) {
                        break;
                    }
                }
            } else {
                aheadIndex = 2;
            }
            aheadCarPosition = allCars[aheadIndex].y;
        }
        _;
        delete cars;
        aheadIndex = 0;
        remainingBalance = 0;
        speed = 0;
        shields = 0;
        bananaBought = false;
        superShellBought = false;
        ACCEL_MAX = 50;
        SUPER_SHELL_MAX = 300;
        SHELL_MAX = 150;
        SHIELD_MAX = 150;
    }

    function takeYourTurn(
        Monaco monaco,
        Monaco.CarData[] calldata allCars,
        uint256[] calldata bananas,
        uint256 ourCarIndex
    ) external override setUp(allCars, bananas, ourCarIndex) {
        Monaco.CarData memory ourCar = allCars[ourCarIndex];
        uint256 ourCarPosition = allCars[ourCarIndex].y;
        uint256 aheadDistance = aheadCarPosition - ourCarPosition;
        if (ourCar.y >= 875) {
            getBananasOutOfTheWay(monaco);
            buyAccelerationFor(monaco, remainingBalance / 2);
        } else {
            if (ourCarIndex == 0) {
                buyAccelerationFor(monaco, 300);
                buyFreeStuff(monaco);
                if ((ourCarPosition % 2) == 1) {
                    monaco.buyBanana();
                }
            } else {
                uint256 targetPurchase;
                if (aheadDistance <= SAFE_DISTANCE) {
                    targetPurchase = 500;
                    if (shields == 0) {
                        buy1ShieldIfPriceIsGood(monaco);
                    }
                } else {
                    targetPurchase = 1000;
                }
                if (remainingBalance < targetPurchase) {
                    buyFreeStuff(monaco);
                    return;
                }
                buyAccelerationFor(monaco, targetPurchase);
            }
        }
    }

    function buy1ShieldIfPriceIsGood(Monaco monaco) internal {
        // Buy a shell if the price is good but keep a small balance just in case we need to accelerate again
        if (monaco.getShieldCost(1) < 300) {
            monaco.buyShield(1);
        }
    }

    function buyFreeStuff(Monaco monaco) private {
        if (monaco.getAccelerateCost(1) == 0) {
            monaco.buyAcceleration(1);
            // speed += 1;
        }
        if (monaco.getShieldCost(1) == 0) {
            monaco.buyShield(1);
            // shields += 1;
        }
        if (monaco.getBananaCost() == 0) {
            monaco.buyBanana();
            // bananaBought = true;
        }
        if (monaco.getSuperShellCost(1) == 0) {
            monaco.buySuperShell(1);
            // superShellBought = true;
        }
        if (monaco.getShellCost(1) == 0) {
            monaco.buyShell(1);
            if (bananasAhead > 0) {
                --bananasAhead;
                return;
            }
            if (aheadIndex != 2) {
                if (cars[aheadIndex].shield > 0) {
                    --cars[aheadIndex].shield;
                    return;
                }
                cars[aheadIndex].speed = 1;
                return;
            }
        }
    }

    function buyAccelerationFor(Monaco monaco, uint256 target) private {
        buyFreeStuff(monaco);
        uint256 price = 0;
        uint256 i = 0;
        while (price <= target) {
            ++i;
            price = monaco.getAccelerateCost(i);
            if (gasleft() < 1_000_000) break;
        }
        --i;
        if (i > 0) {
            remainingBalance -= monaco.buyAcceleration(i);
            speed += i;
        }
    }

    function getBananasOutOfTheWay(Monaco monaco) private {
        uint256 remainingBananas = bananasAhead;
        if (remainingBananas == 0) return;
        uint256 shellCost = monaco.getShellCost(remainingBananas);
        uint256 superShellCost = monaco.getSuperShellCost(1);
        if (shellCost > superShellCost) {
            // buy super shell
            monaco.buySuperShell(1);
        } else {
            // buy shells
            monaco.buyShell(remainingBananas);
        }
    }

    function buyAcceleration(
        Monaco monaco,
        uint256 amount
    ) private returns (bool) {
        uint256 cost = monaco.getAccelerateCost(amount);
        // don't buy if price exceeds maximum
        if (cost > (ACCEL_MAX * amount)) return false;
        if (cost < remainingBalance) {
            remainingBalance -= monaco.buyAcceleration(amount);
            speed += amount;
            return true;
        }
        return false;
    }

    function buyBanana(Monaco monaco) private returns (bool) {
        if (aheadIndex == 0 || bananaBought) return false;
        uint cost = monaco.getBananaCost();
        if (cost > BANANA_MAX) return false;
        if (cost < remainingBalance) {
            remainingBalance -= monaco.buyBanana();
            bananaBought = true;
            return true;
        }
        return false;
    }

    function sayMyName() external pure returns (string memory) {
        return "Koankem";
    }
}
