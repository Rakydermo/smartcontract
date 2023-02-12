// Version de solidity del Smart Contract
// SPDX-License-Identifier: UNLICENSED


pragma solidity ^0.8.16;

// Informacion del Smart Contract
// Nombre: Reserva
// Logica: Implementa subasta de productos entre varios participantes

// Declaracion del Smart Contract - Auction
contract  RandomValidators{

    mapping (uint256 => uint256) public number;
    uint count;
    
    function selectOlddNumbers(uint256 _max) public view returns (uint[] memory) {
        require(_max >= 50, "No hay 50 validadores");
        uint[] storage total ;
        for(uint i = 0; i < 10 ; i ++){
            uint256 random = selectOldNumber(_max);
            if(number[random] == 0){
                number[random] = random;
                total.push(random);
            }else{
                i--;
            }
        }
        return total;
    }

    function selectOldNumber(uint256 _max) private view returns (uint256){
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)) % (_max / 2 + 1 ) + (_max /2));
    }


}