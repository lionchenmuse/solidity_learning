// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract testEnum {
    enum Color {
        Red,
        White,
        Blue
    }
    Color color;

    function setColor(Color c) public {
        color = c;
    }

    function getColor() public view returns (Color) {
        return color;
    }

    function getMaxValue() public pure returns (Color) {
        return type(Color).max;
    }

    function getMinValue() public pure returns (Color) {
        return type(Color).min;
    }
}