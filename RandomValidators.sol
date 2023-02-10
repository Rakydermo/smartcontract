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
    
    function selectOlddNumbers(uint256 _max) public view returns (mapping (uint256 => uint256) memory){
        require(_max <= 0 && _max >= 5 , "tiene que se mayor que 0");
        if(_max % 2 == 0){
            count =_max/2 + 1; 
        }else {
            count =_max/2;
        }
        
        uint selectedCount = 0;
        for(uint i = 0; i < count ; i ++){
            uint256 random = selectOldNumber(_max);
            if(number[random] == 0){
                number[random] = random;
                selectedCount++;
            }else{
                i--;
            }
        }
        return number;
    }

    function selectOldNumber(uint256 _max) private view returns (uint256){
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)) % (_max / 2 + 1 ) + (_max /2));
    }


}