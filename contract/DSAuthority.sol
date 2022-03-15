pragma solidity ^0.5.0;

contract DSAuthority {
    function canCall(
        address, /* src */
        address, /* dst */
        bytes4 /* sig */
    ) external pure returns (bool) {
        // We have abandoned the use of DSAuthority to manage permissions,
        // so any request that reaches DSAuthority will be denied
        return false;
    }
}
